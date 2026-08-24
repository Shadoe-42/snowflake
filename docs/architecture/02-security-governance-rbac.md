# Security, Governance & RBAC

Status: draft (full prose, 2026-08-24)

Security in Snowflake spans two distinct problems that are easy to conflate: who is allowed
to do what (RBAC), and what happens to sensitive data regardless of who's touching it
(governance -- classification, masking, lineage, quality). Both matter, and both are worth
getting right from the start, because retrofitting either onto an existing account is
significantly more painful than designing them in from day one.

## Role hierarchy

The naive approach to Snowflake RBAC is "grant `SYSADMIN` to everyone who needs to get work
done." It's also the approach that becomes ungovernable the moment more than a handful of
people touch the account -- there's no way to answer "who can read this schema" without
tracing a tangle of ad hoc grants. The production-ready alternative is a four-layer role
hierarchy that separates *what a privilege is* from *who needs it*:

- **Access Roles (AR)** are atomic: one schema, one privilege, nothing else. Named
  `AR_<DB>_<SCHEMA>_<PRIVILEGE>` (e.g. `AR_SALES_ORDERS_SELECT`), they exist purely to hold a
  grant, never to be assigned to a person directly.
- **Functional Roles (FR)** bundle access roles into something that maps to how the
  organization actually thinks about work -- a team, a business function.
  `FR_<BUSINESS_UNIT>_<FUNCTION>` (e.g. `FR_FINANCE_ANALYST`) holds no direct object
  privileges of its own; it only inherits from access roles. This is what actually gets
  granted to a person.
- **Service Roles (SR)** exist to isolate automation -- pipelines, BI tool service accounts,
  CI/CD -- from human identities, using the convention `FR_SVC_<APPLICATION_OR_PIPELINE>`.
  This matters because automation credentials get rotated, audited, and revoked differently
  than human accounts, and mixing the two makes both harder to reason about.
- Everything rolls up to `SYSADMIN` so governance and audit visibility stay centralized, even
  though `SYSADMIN` itself is no longer where day-to-day privileges are granted.

The rule that holds the whole thing together: grant privileges to roles, grant roles to other
roles or to users, and never grant a privilege directly to an individual user. The moment a
privilege is granted directly to a person, the role hierarchy stops being an accurate picture
of who can do what, and that's the exact failure mode this structure exists to prevent.

**Scale on-ramp.** This full four layers is where an account lands as team size and
compliance requirements grow -- it is not where a first deployment needs to start. A
reasonable starting point is Access Roles plus Functional Roles only; skip the Service Role
layer until there are actually multiple automated pipelines or tools that need identities
isolated from each other. What should hold from the very first day regardless of how many
layers are in play: privileges go to roles, never to users. That discipline is nearly free to
maintain from the start and expensive to retrofit once direct user grants have accumulated.

## Catalog, classification & data protection

Horizon Catalog is Snowflake's governance backbone, and it's worth treating as a first-class
part of the architecture rather than something bolted on after the fact. It's where tagging,
classification, lineage tracking, and access-control visibility all live centrally, instead
of being configured per-object as an afterthought. Practically, this means sensitive data
gets tagged once (e.g. `PII`, `FINANCIAL`) and policies attach to the tag rather than to every
individual table and column that happens to contain that kind of data -- new tables that get
the same tag inherit the same protection automatically.

That tag-driven model is what makes data masking, row access policies, and (per Snowflake's
own white paper) projection and differential privacy policies practical at scale: applying
protection at the tag level means it follows the data as new objects are created, rather than
requiring someone to remember to configure masking on every new table that happens to contain
a customer's SSN.

Data quality is the other half of governance that reference architectures tend to skip:
"is the data actually good" is a real operational question, not a nice-to-have. Snowflake's
data metric functions -- built-in and custom -- can be centrally defined and run in the
background against data as it lands, capturing results for review rather than requiring a
separate quality-monitoring tool bolted onto the platform.

## Authentication

Single sign-on and multi-factor authentication are baseline requirements, not optional
hardening to add later. This should be part of account setup from the very first day, not a
follow-up task -- there is no meaningful reason to stand up an account without both, and
retrofitting SSO/MFA onto an account with established user habits is more disruptive than
just starting with it.

## Network policies

This is flagged honestly as not yet fully scoped. The white paper that surfaced much of the
governance content above names network policies as a capability but doesn't provide enough
depth to document responsibly here. This needs its own docs-verified research pass before
it's build-ready -- treat it as an open item, not an oversight.

## Sources

- Building a Production-Ready Snowflake RBAC -- Snowflake Builders Blog:
  https://medium.com/snowflake/building-a-production-ready-snowflake-rbac-architecture-best-practices-and-setup-guide-73ce30e4db78
- "Modern Data Platform Requirements" white paper, Snowflake Inc., 2025 (private research
  directory, not part of this repo) -- vendor material, treated as a capability map, not
  independent verification.
