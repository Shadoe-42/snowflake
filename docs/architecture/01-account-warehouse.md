# Account & Warehouse Architecture

Status: draft (full prose, 2026-08-24)

Every Snowflake deployment starts with the same basic question: how is compute organized so
that different kinds of work don't fight each other for resources, and don't quietly rack up
cost while sitting idle? The answer lives almost entirely in how virtual warehouses are
scoped, sized, and governed.

## Workload isolation

Snowflake's storage/compute separation (see "Why this works" below) means a virtual
warehouse is nothing more than a named compute cluster pointed at shared storage -- there's
no cost or architectural penalty to running several of them side by side. That makes
workload isolation the default, not a luxury: give ELT/transform jobs their own warehouse,
give BI/dashboard queries a separate one, give data science notebooks another, and reserve a
warehouse for GenAI/Cortex work once Phase 2 gets there. Two things fall out of this for
free. First, a runaway transform job can't starve an executive's dashboard of compute --
they're physically separate clusters. Second, cost attribution becomes trivial: warehouse-
level usage is warehouse-level cost, so "how much are we spending on BI" is a query away
instead of a spreadsheet exercise.

## Scaling: multi-cluster warehouses

For a warehouse that sees real concurrency -- many users or jobs hitting it at once --
Snowflake's multi-cluster warehouses are the mechanism for handling that without a human
resizing anything by hand. A multi-cluster warehouse scales the number of running clusters
up and down automatically as concurrent query load fluctuates, then scales back down (and
eventually suspends, see below) when load drops.

This is not a day-one requirement for every warehouse. A warehouse serving a handful of
scheduled transform jobs has no concurrency problem to solve and gains nothing from
multi-cluster configuration. The right approach is to start single-cluster everywhere, watch
for queuing (`STATEMENT_QUEUED_TIMEOUT_IN_SECONDS`, below, is a useful tripwire for this),
and turn on multi-cluster specifically for the warehouses that demonstrate real contention --
typically BI/dashboard warehouses under concurrent user load. Treat it as a lever you reach
for, not a setting you apply everywhere out of caution.

## Auto-suspend and auto-resume

Every warehouse should have auto-suspend enabled, without exception, and every warehouse with
auto-suspend enabled should also have auto-resume enabled. This pairing matters: auto-suspend
alone (without auto-resume) just turns "idle warehouse" into "warehouse someone has to
remember to manually restart," which defeats the purpose. Together, they mean a warehouse
costs nothing while nobody's using it and comes back automatically the moment a query needs
it -- typically well under a second of added latency, since the compute is deallocated but
the warehouse configuration and cache state are preserved.

Because this setting is a direct lever on cost, restrict who can disable it. A warehouse with
auto-suspend quietly turned off by a well-meaning engineer debugging something is one of the
more common ways Snowflake bills surprise people.

## Access control on warehouses

`CREATE WAREHOUSE` and the `MODIFY` privilege on existing warehouses should sit with a small,
deliberate set of roles -- not be broadly granted. This isn't about mistrust; it's about
preventing two specific failure modes: warehouse sprawl (every team spinning up its own
warehouse instead of reusing an appropriately-scoped one) and accidental upsizing (someone
bumping a warehouse from Small to X-Large to "make a slow query faster" without understanding
the cost multiplier that comes with it). Centralizing warehouse lifecycle management in a
small admin set keeps both in check without adding meaningful friction to day-to-day work,
since day-to-day work is running queries against existing warehouses, not creating new ones.

## Query and queue timeouts

Two session/warehouse-level parameters are cheap insurance against runaway cost:
`STATEMENT_TIMEOUT_IN_SECONDS` cancels a query that's been running too long, and
`STATEMENT_QUEUED_TIMEOUT_IN_SECONDS` cancels a query that's been queued too long waiting for
a busy warehouse. Both can be set at account, user, session, or warehouse level, and when
multiple levels apply, the lowest non-zero value wins -- which means a sensible account-wide
default plus tighter overrides on specific warehouses is a reasonable pattern, rather than
configuring every level individually.

## Why this works: storage/compute separation

Everything above -- cheap workload isolation, per-second auto-suspend economics, multi-
cluster scaling without manual resizing -- is a consequence of one architectural decision:
Snowflake separates storage from compute and scales each independently. Warehouses don't own
data; they're compute attached to shared, durable storage on demand. That's worth stating
explicitly rather than treating each of the above as an independent best practice, because it
explains *why* the practices hold: there's no data-movement cost to spinning up a new
warehouse, no data-duplication cost to running several at once, and no meaningful latency
cost to suspending and resuming one. The pattern only makes sense because the underlying
architecture makes it cheap.

## Harborline in practice

Harborline runs three warehouses today, matching the workload-isolation split above:
`HARBORLINE_WH_ELT` for nightly order/shipment loads out of the TMS, `HARBORLINE_WH_BI` for
dispatch dashboards, and `HARBORLINE_WH_DATA_SCIENCE` for route-optimization notebooks (see
`terraform/core/warehouses.tf`). All three are single-cluster and share one account-level
resource monitor -- Harborline doesn't have per-warehouse budget lines yet, so credit
consumption is tracked at the account level for now, with the option to split later if any
one warehouse's spend needs its own visibility. Auto-suspend is 60 seconds across the board,
which suits ELT (scheduled, bursty) and data science (interactive, idle between runs) well;
`HARBORLINE_WH_BI` is the one to watch as more dispatchers start hitting live dashboards
during peak shipping windows -- the first candidate to flip to multi-cluster once queuing
shows up, not before.

## Sources

- Cost controls for warehouses -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/cost-controlling-controls
