# Terraform

Status: PLACEHOLDER -- not started.

Sequencing decision (alongside docs vs. second pass after docs stabilize) not yet made --
revisit once docs/architecture/ has a full first draft.

Planned structure once started: a cloud-agnostic core module (Snowflake account/warehouse/
RBAC objects) plus per-cloud submodules (aws/, gcp/) for the underlying cloud resources
described in docs/integrations/csp-crosswalk.md.

Known open item: Terraform provider (Snowflake-Labs/terraform-provider-snowflake) coverage
gaps not yet researched -- Iceberg/Polaris and Horizon Catalog resources specifically worth
checking before relying on them, since these are newer Snowflake capabilities and provider
support tends to lag.
