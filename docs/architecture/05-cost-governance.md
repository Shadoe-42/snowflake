# Cost Governance

Status: draft, seeded from research (2026-08-24)

- Resource monitors on every warehouse/account boundary -- credit limits by time interval,
  can suspend warehouses at threshold. One monitor can cover multiple warehouses.
- Overlaps heavily with 01-account-warehouse.md -- when this becomes prose (not just bullets),
  consider documenting cost governance and warehouse architecture together rather than as
  fully separate pieces, since the controls live in the same place.
- Per-second usage-based pricing underlies why auto-suspend/resume tuning actually matters --
  connect the mechanism to the pricing model rather than presenting auto-suspend as a best
  practice in a vacuum.

## Sources

- Cost controls for warehouses -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/cost-controlling-controls
