# Sharing & Data Clean Rooms

Status: draft (full prose, 2026-08-24)

Secure Data Sharing and Data Clean Rooms are documented together because they're one
mechanism, not two: a Clean Room is Secure Data Sharing plus a privacy-preserving query
layer on top, not a separate product built from scratch. Understanding the plain sharing
primitive first is what makes the clean-room layer legible rather than magic.

## Secure Data Sharing, the primitive

A Snowflake share grants another account live, governed access to specific objects --
tables, secure views, or the last-mile of Data Sharing that isn't in this repo's scope,
whole applications via the Native App Framework -- without copying any data. The consumer
queries against the provider's storage directly, under whatever privileges the share
actually grants; there's no extract, no file drop, no data at rest on the consumer's side
that the provider has to track or expire. `terraform/sharing/secure_view_and_share.tf`
builds one: `LANTERNES_SHARE_MERCHANT_INSIGHTS`, granted `USAGE` on the database and schema
and `SELECT` on exactly one secure view -- nothing else in the schema is reachable through
this share, whatever else exists alongside it.

## What actually makes it privacy-preserving

The most important design decision in `terraform/sharing/` isn't a policy, it's what the
share exposes in the first place: `LANTERNES_V_MERCHANT_INSIGHTS` is a secure view that
aggregates `TRANSACTIONS` to merchant, merchant category code, and day -- transaction counts
and summed amounts, never an individual row. There is no cardholder-level join surface in
that view for a consumer to reach, even in the hypothetical where every policy layered on
top of it were misconfigured. That ordering matters: aggregation is the privacy boundary
itself, not a control bolted onto raw data after the fact.

Aggregation alone isn't sufficient, though, and it's worth being honest about where it falls
short: a low-volume cell -- a single-transaction day for a small merchant -- leaks that
transaction's exact amount through the aggregate itself, no join required. The view's
`HAVING COUNT(*) >= 10` (the threshold is `var.min_aggregation_cell_size`, illustrative, not
derived from a rigorous privacy analysis) is basic small-cell suppression against that
specific leak. It is not a formal differential-privacy guarantee, and shouldn't be
represented as one -- Snowflake has real differential-privacy tooling for organizations that
need that stronger guarantee, and adopting it is a reasonable next step this repo doesn't
attempt.

Row-level scoping is a second, independent control on top of the aggregation boundary, not a
restatement of it: which `MERCHANT_ID` rows a given consumer's aggregates cover is enforced
by `terraform/sharing/row_access.tf`, scoped by database role rather than account identity.
This corrects an earlier draft of this module, which checked `CURRENT_ACCOUNT()` against a
mapping table -- that isn't how Snowflake actually scopes row access on shared data, verified
against Snowflake's own documentation after the fact. The real mechanism: grant a distinct
database role to each consumer through the share (`snowflake_grant_database_role`, with
`share_name` set), and have the row access policy check `IS_DATABASE_ROLE_IN_SESSION()`
against it. One share, multiple database roles granted to it, multiple visibility levels --
`LANTERNES_DBROLE_PARTNER_ACME` illustrates the shape one onboarded partner's role would
take; a real deployment would have one such role per partner. `LANTERNES_DBROLE_INTERNAL_ANALYST`
gets full visibility and is never granted to any share -- also not yet wired to an actual
account role or user, since Lanternes' broader RBAC (the `terraform/core` equivalent
Harborline has) wasn't built for this phase, per `docs/fin-warehouse/00-overview.md`.

A column-level masking policy was deliberately left out of this module, after an earlier
draft included one that protected nothing: it referenced `CARD_TOKEN`, a column the shared
view never selects in the first place, and was never actually attached to any column via a
masking policy application. Rather than keep a policy that exists for the appearance of a
control, this module relies on the aggregation boundary doing the actual work -- there is no
object in `terraform/sharing/` that a masking policy would meaningfully protect. A stricter,
internal-only view that did surface `CARD_TOKEN` for fraud or ops use would be a legitimate
reason to add one back, scoped to that view specifically -- not built here.

A tag (`terraform/sharing/classification.tf`) marks `CARD_TOKEN` as `cardholder_data` and
the secure view itself as `aggregated` -- the same Horizon Catalog tag-driven pattern
documented in `docs/architecture/02-security-governance-rbac.md`, both values actually
applied to something rather than left as unused enum options.

## Where Data Clean Rooms add a layer

Everything above is plain Secure Data Sharing -- real, Terraformed, and sufficient for
Lanternes' actual scenario: a merchant or advertiser partner wants aggregated
purchase-behavior insight (what gets bought, when, at what volume) without ever seeing
individual transactions. Snowflake's Data Clean Rooms product, built on the Native App
Framework, exists for a harder problem this scenario doesn't require: two parties who each
want to run analysis *across* their combined data (a join, not just a one-directional read)
without either side seeing the other's raw records -- the "how many customers do we have in
common" class of question, answered as a count, never as a list of names.

Worth flagging honestly rather than asserting confidently: Snowflake's own current
documentation describes Clean Room policy enforcement two different ways in two different
places -- one describes row access policies plus Jinja-templated stored procedures and UDFs,
another describes join/column/activation policies enforced through analysis templates. That
inconsistency reads like product evolution rather than a documentation error, but this repo
isn't going to assert a single mechanical model as fact when Snowflake's own material
doesn't agree with itself. Anyone implementing an actual cross-party clean room should verify
the current mechanism against current docs before building against either description --
the same verify-before-writing discipline that caught the `CURRENT_ACCOUNT()` mistake above,
applied here as a forward warning instead of a retrospective fix. There's also no dedicated
Terraform resource for the Clean Rooms product itself in the pinned provider -- it's
Marketplace/Native-App-provisioned, not SQL DDL, so it stays documented-only here, the same
treatment given to private connectivity in Phase 1 and Document AI in Phase 2.

## A note on scope

This is architecture reasoning, not compliance or legal guidance. Payment transaction data
and any real data-monetization program built on it require actual legal and compliance
review specific to the regulations that apply -- this doc models a privacy-preserving
technical pattern, nothing more, and shouldn't be read as a substitute for that review.

## Marketplace, briefly

This is also how third-party data typically arrives at an organization -- as a share,
consumed via Snowflake Marketplace's browse-and-buy layer rather than a private point-to-point
share like the one built here. The storefront aspect itself is out of scope by design for
this repo: real operational experience with CSP marketplaces has been mixed enough to treat
"browse and buy" as a footnote, not something worth architecting around here.

## Sources

- Share data protected by a policy -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/data-sharing-policy-protected-data
- Understanding row access policies -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/security-row-intro
- Understanding Snowflake Data Clean Room policies -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/cleanrooms/v1/policies
- Snowflake Data Clean Room Q&A -- Snowflake Blog: https://www.snowflake.com/en/blog/data-clean-room-qa/
- Mastercard Data Clean Room -- Mastercard: https://www.mastercard.com/global/en/business/insights-intelligence/advanced-analytics/solutions/mastercard-data-clean-room.html
- "Data Sharing Best Practices," Snowflake Inc. (private research directory, not part of
  this repo) -- schema drift and data-change handling for live shares; grounds the "shares
  are live and governed, not a copy" framing above.
