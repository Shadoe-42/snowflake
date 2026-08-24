# Workload isolation: ELT/transform, BI, and data science each get their own warehouse
# rather than sharing one. See docs/architecture/01-account-warehouse.md for why -- a
# runaway transform job can't starve a dashboard query when they're physically separate
# compute clusters, and per-warehouse usage makes cost attribution trivial.
#
# Every warehouse here is single-cluster by default (min = max = 1). Multi-cluster is a
# lever to reach for once a specific warehouse demonstrates real concurrency contention --
# not a day-one default applied uniformly. See the scale on-ramp note in
# docs/architecture/01-account-warehouse.md. The BI warehouse is the most likely candidate
# to need it first, once concurrent dashboard users show up.

resource "snowflake_warehouse" "elt" {
  name    = upper("${var.org_prefix}_wh_elt")
  comment = "ELT/transform workloads. Isolated from BI and data science."

  warehouse_size      = var.elt_warehouse_size
  auto_suspend        = var.warehouse_auto_suspend_seconds
  auto_resume         = "true"
  initially_suspended = true

  min_cluster_count = 1
  max_cluster_count = 1

  resource_monitor = snowflake_resource_monitor.account.name
}

resource "snowflake_warehouse" "bi" {
  name    = upper("${var.org_prefix}_wh_bi")
  comment = "BI/dashboard query workloads. First candidate for multi-cluster once concurrent users show up."

  warehouse_size      = var.bi_warehouse_size
  auto_suspend        = var.warehouse_auto_suspend_seconds
  auto_resume         = "true"
  initially_suspended = true

  min_cluster_count = 1
  max_cluster_count = 1

  resource_monitor = snowflake_resource_monitor.account.name
}

resource "snowflake_warehouse" "data_science" {
  name    = upper("${var.org_prefix}_wh_data_science")
  comment = "Data science / notebook workloads, isolated from operational ELT and BI warehouses."

  warehouse_size      = var.data_science_warehouse_size
  auto_suspend        = var.warehouse_auto_suspend_seconds
  auto_resume         = "true"
  initially_suspended = true

  min_cluster_count = 1
  max_cluster_count = 1

  resource_monitor = snowflake_resource_monitor.account.name
}
