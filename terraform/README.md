# Terraform

Five independent modules. Each validates on its own; none of them reference
each other via Terraform (no remote state data sources, no module blocks) --
the coupling between them is documented, not wired.

| Path | What is there |
|---|---|
| `core/` | Cloud-agnostic Snowflake-provider resources: resource monitor, warehouses, database/schemas, RBAC (Access Roles + Functional Roles). Applies to any Snowflake account regardless of which cloud it's hosted on. |
| `aws/` | The AWS half of the [CSP crosswalk](../docs/integrations/csp-crosswalk.md): S3 landing bucket, IAM role/trust policy, `snowflake_storage_integration_aws`, and the direct S3-to-SQS Snowpipe auto-ingest wiring. |
| `gcp/` | The GCP half of the same crosswalk: GCS landing bucket, `snowflake_storage_integration_gcs`, and the GCS-notification-to-Pub/Sub Snowpipe auto-ingest wiring via a `snowflake_notification_integration`. |
| `genai/` | Phase 2: a semantic view for Cortex Analyst, a Cortex Search service, and a Cortex Agent tying both together -- see [docs/genai/](../docs/genai/). |
| `sharing/` | Phase 3: tag classification, a database-role-scoped row access policy, a pre-aggregated (small-cell-suppressed) secure view, and a share exposing only that view -- see [docs/sharing/sharing-clean-rooms.md](../docs/sharing/sharing-clean-rooms.md). |

## Why separate modules instead of one

`core` is genuinely cloud-agnostic -- there's nothing in it that changes based
on which cloud is hosting the Snowflake account. `aws` and `gcp` are the two
places in this repo's scope where the integration is provider-specific enough
that Terraform resources actually differ by cloud, not just by naming
convention. Splitting them means a reader (or CI) evaluating "what does the
AWS integration path look like" doesn't have to mentally filter out GCP
resources, and vice versa. `genai` is a different kind of split again -- not
cloud-specific like `aws`/`gcp`, but phase-specific: it's Phase 2 work layered
on top of the Phase 1 foundation `core` builds, and keeping it separate means
someone evaluating Phase 1 alone doesn't have to read past Cortex resources
that assume Phase 1 already exists. `sharing` is Phase 3, on the same
phase-specific logic as `genai` -- it's Lanternes' module, not Harborline's,
built against a different illustrative database (`LANTERNES`, not
`HARBORLINE`) entirely.

## What's intentionally *not* here

Private connectivity (AWS PrivateLink / GCP Private Service Connect) is
covered in the crosswalk doc but not Terraformed. Both require an interactive
handshake with Snowflake support to provision the account-side endpoint
before any client-side resource can be created, and what exists afterward on
the client side is thin (an endpoint and a couple of DNS entries) relative to
the manual coordination required to get there. That combination -- a
process, not a resource -- doesn't fit well as Terraform state, so it stays
documented only.

The target tables referenced in each module's `copy_statement` (e.g.
`RAW_LANDING`) aren't defined anywhere in these modules. Table DDL belongs
with concrete data-modeling examples, not with the ingestion plumbing, and
Harborline's data model doesn't exist yet in this repo -- see the Phase 1
open items in `TRACKING.md`. The same is true of `genai/`'s `SHIPMENTS` and
`CARRIER_DOCUMENTS` -- both illustrative, neither created by this repo's
Terraform. See `docs/genai/00-overview.md` for what else is deliberately out
of scope in Phase 2 (Document AI, Cortex Functions, Snowflake ML). `sharing/`'s
`TRANSACTIONS` and `MERCHANT_ENTITLEMENTS` follow the same pattern -- see
`docs/fin-warehouse/00-overview.md`. Snowflake's Data Clean Rooms product
itself (as opposed to the plain Secure Data Sharing this module builds) has
no dedicated Terraform resource in the pinned provider -- it's
Marketplace/Native-App-provisioned, so it stays documented-only, per
`docs/sharing/sharing-clean-rooms.md`.

`sharing/` originally included a masking policy on `CARD_TOKEN`. It was removed, not
patched: the shared secure view never selects that column, and the policy was never
attached to any column via a masking policy application, so it protected nothing --
caught during a deliberate adversarial self-review, not by `terraform validate` (which
only checks syntax, not whether pieces are actually wired together). That review also
caught that the row access policy's original mechanism, a `CURRENT_ACCOUNT()` self-join,
isn't how Snowflake actually scopes row access on shared data -- it now uses
`IS_DATABASE_ROLE_IN_SESSION()` against a database role granted to the share, matching
Snowflake's documented pattern. See `docs/sharing/sharing-clean-rooms.md` for the full
account.

A second adversarial self-review pass, this one against `core/`, `aws/`, and `genai/`
(Phase 1 and Phase 2), caught three more defects of the same class -- plausible-looking
things that `terraform validate` had no way to catch because it only checks syntax, not
whether the pieces actually do what the docs claim:

- `core/rbac.tf` provisioned `HARBORLINE_WH_DATA_SCIENCE` with no Functional Role ever
  granted USAGE on it, even though `docs/architecture/01-account-warehouse.md` described
  it as already running real notebooks. Unlike every other unbuilt piece in this repo, that
  gap was never flagged as deliberately deferred. Fixed by adding
  `HARBORLINE_FR_DATA_SCIENTIST`, granted `HARBORLINE_AR_ANALYTICS_SELECT` and warehouse
  USAGE, the same shape as `fr_analyst`.
- `genai/variables.tf` declared an `analyst_warehouse` variable, described as the warehouse
  Cortex Analyst's generated SQL runs against -- and `docs/genai/01-cortex-analyst.md`
  repeated that as fact. `snowflake_semantic_view` has no warehouse attribute (confirmed
  against the live provider schema); the variable was never referenced by any resource.
  Removed, and the doc corrected to explain the real mechanism: the query runs on whatever
  warehouse the caller's role already has USAGE on via `core/rbac.tf`, an RBAC/session
  property, not something this module configures.
- `aws/storage_integration.tf` granted `s3:PutObject`/`s3:DeleteObject` unconditionally,
  though nothing in this repo's pipe unloads or purges data, and `gcp/storage_integration.tf`
  correctly scopes the equivalent grant to read-only for the identical ingestion job.
  Tightened to `s3:GetObject` only, matching GCS.

Two stale status lines from before Phase 2 and Phase 3 existed --
`docs/architecture/00-overview.md` still saying sharing was "not started," and this doc's
own CSP-crosswalk companion still calling the AWS/GCP Terraform "a placeholder" -- were
also caught and corrected in the same pass.

## The AWS two-phase apply

`aws/storage_integration.tf` has a real circular dependency to work around:
the IAM role's trust policy needs to trust Snowflake's own IAM identity and a
Snowflake-generated external ID, but neither of those exist until *after* the
storage integration that references the role has been created. Snowflake's
own documented process handles this manually (create the integration, run
`DESCRIBE INTEGRATION`, paste the values into the console). This module
captures the same shape as Terraform inputs and outputs instead of console
clicks:

1. `terraform apply` with the default placeholder values for
   `snowflake_iam_user_arn` and `snowflake_external_id` (a trust policy that
   trusts nothing real yet, but is valid HCL).
2. Read `storage_integration_iam_user_arn` and `storage_integration_external_id`
   from the outputs.
3. `terraform apply -var snowflake_iam_user_arn=... -var snowflake_external_id=...`
   to tighten the trust policy to the real values.

This is a real two-step process, not a Terraform limitation to work around
cleverly -- trying to force it into one apply would mean either a fake
placeholder that never gets tightened, or a dependency cycle Terraform will
reject outright.

GCP has no equivalent step: `snowflake_storage_integration_gcs` generates its
own service account, and the IAM binding granting that service account
access to the bucket happens in the same apply.

## Validating

Each module is `terraform init && terraform validate`-clean against the
pinned provider versions in its own `.terraform.lock.hcl`. CI runs `terraform
fmt -check` and `terraform validate` against all five on every push -- see
`.github/workflows/terraform-ci.yml`.

None of this has been applied against a live Snowflake account, AWS account,
or GCP project. "Validates" means syntactically and referentially correct
Terraform, not "has been run against real infrastructure." See the repo
README's "What this is, and is not" section.
