# Security, Governance & RBAC

Status: draft, seeded from research (2026-08-24)

## Role hierarchy

Four-layer role hierarchy (production-ready pattern, not the toy "just use SYSADMIN" version):

- **Access Roles (AR)** -- atomic, one schema + one privilege each. AR_<DB>_<SCHEMA>_<PRIVILEGE>.
- **Functional Roles (FR)** -- bundle access roles, map to a business function/team.
  FR_<BUSINESS_UNIT>_<FUNCTION>. Never hold direct object privileges.
- **Service Roles (SR)** -- isolate automation (pipelines, BI tools, CI/CD).
  FR_SVC_<APPLICATION_OR_PIPELINE>.
- Everything rolls up to SYSADMIN for governance visibility.
- Hard rule: grant privileges to roles, grant roles to roles/users -- never grant privileges
  directly to a user.

**Scale on-ramp**: the full four-layer hierarchy is where you land as team size and
compliance requirements grow, not where a first deployment needs to start. A reasonable
starting point is Access Roles + Functional Roles only (skip the Service Role layer until
you actually have multiple automated pipelines/tools needing isolated identities), with the
"grant to roles, never to users" rule held firm from day one regardless of layer count --
that discipline is cheap early and expensive to retrofit later.

## Catalog, classification & data protection

- Horizon Catalog as the governance backbone -- tagging, classification, lineage, and access
  control tracking live here rather than being bolted on per-object. First-class piece of
  this architecture, not an afterthought.
- Data masking, row access policies, and projection/differential privacy policies -- apply
  at the tag level where possible so protection follows data automatically rather than
  needing per-table configuration.
- Data quality via data metric functions -- built-in and custom, centrally defined, running
  in the background.
- Authentication: SSO + MFA as baseline, not optional -- table stakes for anything
  resembling production.
- Network policies -- NOT YET SCOPED. Needs a docs-verified pass before this is build-ready.

## Sources

- Building a Production-Ready Snowflake RBAC -- Snowflake Builders Blog:
  https://medium.com/snowflake/building-a-production-ready-snowflake-rbac-architecture-best-practices-and-setup-guide-73ce30e4db78
- "Modern Data Platform Requirements" white paper, Snowflake Inc., 2025 (private research
  directory, not part of this repo) -- vendor material, treated as a capability map, not
  independent verification.
