# CSP Integration Crosswalk: AWS vs. GCP

Status: draft (full prose, 2026-08-24)

The architecture docs in `../architecture/` stay deliberately CSP-neutral -- Snowflake's
SQL, RBAC, and warehouse behavior is genuinely near-identical across clouds, so cloud
specifics don't belong mixed into that core reasoning. But three integration seams do differ
by cloud, and this doc is where those differences live: storage integration, Snowpipe
auto-ingest triggers, and private connectivity. Each section below is written side by side so
the pattern -- same underlying problem, different cloud-native mechanism -- stays visible.

## Storage integration: S3 + IAM vs. GCS + service account

Both clouds solve the same problem the same way in spirit: give Snowflake scoped, credential-
free access to a bucket, rather than embedding long-lived secret keys in a stage definition.
The mechanism each cloud uses to get there is different enough to warrant walking through
separately.

**AWS.** The setup is IAM-role-based and happens in a specific order because of a circular
dependency: Snowflake needs to know about an IAM role before it can tell you the identity
that role needs to trust. First, an IAM policy grants the permissions Snowflake actually needs
against the bucket (`s3:GetBucketLocation`, `s3:GetObject`, `s3:ListBucket`, and optionally
`s3:PutObject`/`s3:DeleteObject` if Snowflake will unload or purge data, not just read it --
`terraform/aws/storage_integration.tf` grants the read-only set, matching GCS below, since
Harborline's raw-landing pipe only ever ingests; an earlier draft granted Put/Delete
unconditionally, tightened after a self-review found nothing in this repo actually used
them).
Second, an IAM role is created with a placeholder trust policy -- "Another AWS account" as the
trusted entity, with a placeholder external ID, since the real values don't exist yet. Third,
`CREATE STORAGE INTEGRATION` in Snowflake references that role's ARN along with allowed (and
optionally blocked) storage locations. Fourth, `DESC INTEGRATION` reveals two values Snowflake
generated: `STORAGE_AWS_IAM_USER_ARN` (the identity Snowflake will actually assume the role
as) and `STORAGE_AWS_EXTERNAL_ID` (a shared secret that prevents the "confused deputy"
problem -- without it, anyone who knew the role ARN could assume it). Fifth, the IAM role's
trust policy gets updated with those real values, closing the loop. Finally, an external stage
in Snowflake references the integration. One operational detail worth knowing: Snowflake
caches temporary credentials for up to 60 minutes, so revoking access at the IAM layer doesn't
take effect instantly.

**GCP.** The flow is shorter because GCP's service-account model doesn't have the same
circular trust-policy problem AWS's does. `CREATE STORAGE INTEGRATION` in Snowflake (account
admin only) specifies the GCS bucket(s) and paths to allow. `DESCRIBE STORAGE INTEGRATION`
then returns a service account ID -- Snowflake auto-provisions this, and notably it's shared
across all GCS storage integrations in the account, not one per integration. In Google Cloud
Console, a custom IAM role is created with the permissions the use case needs (read-only for
loading, broader for unloading) and assigned to that Snowflake service account on the target
bucket. An external stage then references the integration, same as on AWS. One thing to watch
for: Google Cloud projects created after May 3, 2024 may have domain restriction policies
that block the Snowflake service account by default, requiring an explicit policy update, and
KMS-encrypted buckets need Cloud KMS permissions granted separately from the storage
permissions.

**The pattern**: AWS's extra round-trip (placeholder role -> real values -> trust policy
update) exists because IAM roles need to know who's allowed to assume them before that
identity is knowable. GCP sidesteps this because the service account model grants permissions
to an identity that already exists the moment the integration is described, rather than
establishing mutual trust between two sides.

## Snowpipe auto-ingest triggers: SQS/SNS vs. Pub/Sub

Both clouds use the same underlying idea -- a cloud-native event notification service tells
Snowflake a new file landed, without Snowflake having to poll the bucket. The event plumbing
differs.

**AWS.** There are two configurations. In the simpler one, S3 event notifications go directly
to an SQS queue -- Snowflake manages these queues automatically, one per AWS region, and a
queue coordinates notifications across every pipe watching that bucket. The second
configuration inserts SNS as a broadcaster in front of the SQS queue: S3 publishes to an SNS
topic, which fans out to multiple subscribers (the Snowflake-managed SQS queue among them, but
also potentially Lambda functions or other systems). The SNS path is worth reaching for
specifically when something other than Snowpipe also needs to react to the same S3 events --
without it, configuring direct S3-to-SQS for Snowflake would conflict with any existing S3
notification configuration for those events.

**GCP.** Pub/Sub plays the SNS/SQS role in one component instead of two. GCS bucket activity
generates events, and specifically only `OBJECT_FINALIZE` events (a file fully written, not a
partial upload) trigger Snowpipe. A *notification integration* in Snowflake connects to a
Pub/Sub subscription -- notably, one notification integration maps to exactly one
subscription, so multiple pipes watching a bucket share the integration rather than each
getting their own. The storage integration (above) still handles the actual data access; the
notification integration is purely the "something changed" signal.

**The pattern**: AWS separates "something happened" (SNS, optional fan-out) from "Snowflake is
listening" (SQS, always present); GCP collapses that into a single Pub/Sub subscription. Both
converge on the same operational warning worth carrying into any pipe design: don't let
multiple pipes reference overlapping storage locations, since duplicate notifications mean
duplicate loads regardless of which cloud's messaging system delivered them.

## Private connectivity: PrivateLink vs. Private Service Connect

Same goal on both clouds: keep traffic between the organization's VPC and Snowflake off the
public internet entirely, rather than relying on IP allowlisting over a public endpoint. Both
require Snowflake's Business Critical edition or higher, and both follow the same two-phase
shape -- authorize on the Snowflake side, then wire up networking on the cloud side.

**AWS (PrivateLink).** Authorization happens by generating an AWS federated token and calling
`SYSTEM$AUTHORIZE_PRIVATELINK` with the AWS account ID. `SYSTEM$GET_PRIVATELINK_CONFIG` then
returns the private endpoint identifier needed to create a matching AWS VPC endpoint. DNS
comes last: CNAME records map Snowflake's endpoint values to that VPC endpoint's DNS name, so
clients resolving Snowflake's hostname land on the private path rather than the public one.
PrivateLink also supports cross-region VPC connections and can chain with AWS Direct Connect
for genuinely hybrid (on-prem-to-Snowflake) connectivity.

**GCP (Private Service Connect).** The authorization step is the same shape -- call
`SYSTEM$AUTHORIZE_PRIVATELINK`, this time with the GCP project ID and a Google Cloud CLI
access token. The networking side looks different: a private IP address is created within the
target subnet, a forwarding rule routes traffic from that IP to Snowflake's service
attachment, and DNS is updated so Snowflake's hostnames resolve to the private IP rather than
a public one. Traffic flows one-way, from the VPC to Snowflake, over Google's own network
backbone. One concrete constraint worth designing around: GCP enforces a cap of 10 connections
per project and 50 per account.

**The pattern**: the function name (`SYSTEM$AUTHORIZE_PRIVATELINK`) is shared across both
clouds even though the underlying networking primitive isn't -- Snowflake's side of the
handshake is deliberately uniform, and the divergence is entirely in what each cloud's private-
connectivity primitive looks like (a VPC endpoint plus CNAME on AWS, a forwarding rule plus
service attachment on GCP).

## Terraform implications

Storage integration and the notification/event-trigger wiring are built, in `../../terraform/aws/`
and `../../terraform/gcp/` respectively (`terraform validate`-clean against the pinned
provider versions -- see `terraform/README.md`). This section was originally written before
that Terraform existed and called these two "a candidate for its own submodule... once
Terraform work starts" -- stale as of Phase 1's build, corrected here rather than left to
mislead a reader checking the repo's actual state. Private connectivity is the one piece of
this doc that stays documented-only; see `terraform/README.md` for why (an interactive
Snowflake-support handshake, not a resource Terraform state can capture cleanly). The
Snowflake-side resources (`CREATE STORAGE INTEGRATION`, the notification integration, the
`SYSTEM$AUTHORIZE_PRIVATELINK` call) are the same provider regardless of cloud; only the
AWS-provider and google-provider resources on the other side of each integration point
actually diverge.

## Sources

- Option 1: Configure a Snowflake storage integration to access Amazon S3 -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration
- Configure an integration for Google Cloud Storage -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/data-load-gcs-config
- Automating Snowpipe for Amazon S3 -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3
- Automating Snowpipe for Google Cloud Storage -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-gcs
- AWS PrivateLink and Snowflake -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/admin-security-privatelink
- Google Cloud Private Service Connect and Snowflake -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/private-service-connect-google
