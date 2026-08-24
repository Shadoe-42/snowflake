# Cross-Cloud Resilience & Continuity

Status: draft (full prose, 2026-08-24) -- deliberately lighter-weight section

Snowgrid is Snowflake's mechanism for replication and failover across regions and clouds --
covering both data itself and account-level objects like roles and governance policies, so
a failover doesn't just move data without the access controls that were supposed to protect
it.

This section is intentionally kept lighter than the others, and it's worth being honest about
why: this is a real capability, but it's also squarely in "why pay for a managed platform
instead of building resilience yourself on raw cloud storage" marketing territory, which is
exactly the kind of claim this doc set treats with appropriate skepticism rather than
repeating uncritically. The right way to document it is as a capability that exists and the
specific conditions under which it's worth turning on -- not as something every deployment
of this architecture needs by default.

Those conditions are relatively narrow: genuine disaster-recovery requirements with a
business case for cross-region failover, regulatory data-residency constraints that require
data to exist in multiple specific locations, or a deliberate multi-cloud strategy where
workloads need to move between CSPs with minimal friction. Outside of those, a single-region
deployment with the account-level controls described elsewhere in this architecture (RBAC,
governance, cost controls) is a reasonable default, and Snowgrid is a capability to reach for
when one of those specific triggers applies -- not a checkbox to enable preemptively.

## Sources

- "Modern Data Platform Requirements" white paper, Snowflake Inc., 2025 (private research
  directory, not part of this repo) -- vendor material, treated as a capability map, not
  independent verification.
