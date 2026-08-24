# Cortex Agents

Status: draft (full prose, 2026-08-24)

A dispatcher doesn't want to know whether their question needs Cortex Analyst or Cortex
Search -- they just want an answer. Cortex Agents is the orchestration layer that makes
that distinction disappear: it takes a question, decides which tool actually answers it
(sometimes both), calls it, and returns a response, without the person asking needing to
know a semantic view and a search service are two different things under the hood.

## What the agent actually is

`terraform/genai/cortex_agent.tf` defines `HARBORLINE_AGENT_DISPATCH_ASSISTANT` as a
`snowflake_cortex_agent` resource, configured through a YAML specification (the same shape
Snowflake's `CREATE AGENT ... FROM SPECIFICATION` SQL takes) rather than free-form prose
instructions. Three parts do the actual work: `orchestration.budget` caps how much the agent
can spend answering any single question (30 seconds, 16,000 tokens here) -- a cost control
in the same spirit as the resource monitor and auto-suspend discipline from
`docs/architecture/05-cost-governance.md`, just scoped to a single agent turn instead of an
account. `instructions.orchestration` is plain-language routing guidance ("for shipment
questions use Analyst1, for policy questions use Search1") that steers the agent's tool
choice without hand-coding a decision tree. `tool_resources` is where the two prior docs'
Terraform resources actually get wired in: `Analyst1` points at
`HARBORLINE.ANALYTICS.HARBORLINE_SV_SHIPMENTS`, `Search1` points at
`HARBORLINE.ANALYTICS.HARBORLINE_SEARCH_CARRIER_DOCS`. Neither the semantic view nor the
search service needed to be built with agents in mind -- they're referenced by name here
exactly as they'd be used standalone.

## Agent security: no separate identity to manage

The single most important governance property of Cortex Agents, worth stating explicitly
rather than leaving implicit: an agent has no identity of its own. It authenticates and
executes as whichever RBAC principal invoked it -- `HARBORLINE_FR_ANALYST` in the common
case for Harborline's dispatch assistant -- so every privilege boundary already built in
`docs/architecture/02-security-governance-rbac.md` and `terraform/core/rbac.tf` applies to
the agent automatically, with nothing new to grant or audit. There's no "agent service
account" with its own standing access to reason about, and no separate security review the
agent needs beyond the one its invoking role already got. This is a property Snowflake's
platform provides, not a design choice this repo made -- worth noting because it's the
opposite of how a naively-built agent (one that runs under its own broad service credential
"to keep things simple") would behave, and it's the reason Cortex Agents doesn't need its
own RBAC section here beyond a pointer back to the existing one.

## Sources

- Cortex Agents -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents
- CREATE AGENT -- Snowflake Docs: https://docs.snowflake.com/en/sql-reference/sql/create-agent
- Create and manage agents -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage
- "From prompt to purpose: Unlocking business value with agentic AI," Capgemini x
  Snowflake, 2025 (private research directory, not part of this repo) -- source of the
  "agents need workforce-style governance" framing; treated as a capability pointer, not
  independent verification, per the caveat in `00-overview.md`.
