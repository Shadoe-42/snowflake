# Fin Data Warehouse Variant -- Overview

Status: draft (full prose, 2026-08-24)

**Éclairage des Lanternes** is the fictional company anchoring Phase 3, separate from
Harborline Logistics -- a payments processor rather than a logistics operator, chosen
specifically because it needs a genuinely different starting condition than Harborline's,
not because Harborline was stretched to fit a domain it was never meant to represent. The
technical slug used throughout Terraform and identifiers is `lanternes` (plain ASCII,
matching the `harborline` convention); the prose name keeps its full form.

This doc covers what's actually different about a payments fin-data-warehouse relative to
Phase 1's general foundation, not a restatement of it. Warehouse architecture, RBAC
structure, micro-partitions and clustering, the ingestion decision framework -- all of that
from `docs/architecture/` applies to Lanternes exactly as documented for Harborline. What
follows is the delta.

## The business context

Lanternes processes payment transactions and, like real payment processors (Mastercard's
own data clean room product is a real, current example), is exploring how to responsibly
generate value from the purchase-behavior data that processing naturally produces --
what people buy, when, and how. That's also a genuinely scrutinized practice: payment
processors selling transaction data has drawn real regulatory and press attention. Lanternes'
architectural answer, and the reason `docs/sharing/sharing-clean-rooms.md` is this phase's
centerpiece rather than a footnote, is to monetize through privacy-preserving aggregated
insight products instead of raw data licensing -- a technical choice with real reputational
and compliance stakes, not just an engineering preference.

## What's actually different from Harborline

**Volume and velocity.** Payment transactions arrive as a genuine real-time stream, not
periodic batch files the way Harborline's TMS and inventory extracts do. Snowpipe Streaming
-- mentioned but not built out in `docs/architecture/04-ingestion-patterns.md` -- is the
default fit here, not an edge case; row-level, low-latency ingestion matches how transaction
data actually arrives far better than file-based Snowpipe does.

**Sensitive data by default, not by exception.** Every row in Lanternes' transaction data
touches payment card data in some form. `CARD_TOKEN` in the illustrative schema below is
already tokenized -- the actual cardholder number never lands in Snowflake, tokenization
happens upstream in the payment processing path itself, out of this repo's scope. Even a
token gets masked by default here (`terraform/sharing/policies.tf`), on the principle that a
masking policy misconfiguration should degrade to "shows a token" not "shows a real card
number."

**PCI DSS is flagged, not addressed.** This repo does not attempt to document PCI DSS
compliance architecture -- that's a real, audited compliance framework requiring actual
legal and compliance review, not something a reference-architecture repo can responsibly
claim to cover. Treat every sensitive-data pattern here as illustrating the *shape* of a
privacy-preserving architecture, not as compliance guidance. Same honest-gap treatment as
network policies in Phase 1.

## Illustrative data model

`TRANSACTIONS`: `TRANSACTION_ID`, `CARD_TOKEN`, `MERCHANT_ID`, `MCC` (merchant category
code), `AMOUNT`, `TXN_TIMESTAMP`, `TXN_GEOGRAPHY`. Not created by this repo's Terraform --
same scoping choice made for `SHIPMENTS` in Phase 1 and Phase 2. `MERCHANT_ENTITLEMENTS`
(referenced by the row access policy in `terraform/sharing/policies.tf`) maps which merchant
a given share consumer is entitled to see -- also illustrative, also not created.

## Sources

- Mastercard Data Clean Room -- Mastercard: https://www.mastercard.com/global/en/business/insights-intelligence/advanced-analytics/solutions/mastercard-data-clean-room.html
- "PIRG calls out Mastercard's data sales practices" -- Payments Dive: https://www.paymentsdive.com/news/pirg-mastercard-data-sales-practices-payments-card-networks-transactions/695168/
