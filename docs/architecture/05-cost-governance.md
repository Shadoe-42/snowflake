# Cost Governance

Status: draft (full prose, 2026-08-24)

Cost governance in Snowflake isn't really a separate discipline from warehouse architecture
-- the two overlap enough that it's worth reading this doc alongside
[01-account-warehouse.md](01-account-warehouse.md) rather than in isolation. What follows is
the piece that's specifically about capping and monitoring spend, on top of the warehouse-
level controls (auto-suspend/resume, access restrictions, statement timeouts) already covered
there.

## Resource monitors

Resource monitors are the account-level backstop: they set credit-spending limits over a
time interval or date range, and can suspend the warehouses they cover once a threshold is
hit. A single monitor can cover multiple warehouses, or an entire account, which makes them
useful both as a fine-grained control on a specific high-risk warehouse and as a blunt,
account-wide safety net against runaway spend from a misconfiguration or a bug.

## Why auto-suspend actually matters

The reason auto-suspend/resume tuning (covered in the warehouse architecture doc) is worth
getting right rather than treating as a minor convenience setting: Snowflake bills per-second,
usage-based. That pricing model is what makes an idle warehouse a direct, continuous cost
rather than a sunk cost already paid for -- unlike a fixed-capacity on-premise cluster, where
idle time doesn't show up as an additional line item. Auto-suspend isn't a best practice in a
vacuum; it's the mechanism that makes per-second pricing actually save money instead of just
being a different way to bill for the same always-on capacity.

## Sources

- Cost controls for warehouses -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/cost-controlling-controls
