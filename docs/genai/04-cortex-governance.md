# Cortex Governance

Status: draft (full prose, 2026-09-01)

This section exists because governance for an agent platform is not a separate checklist
bolted on afterward -- it is sized to what the agent actually does. That framing is borrowed
directly from a companion reference repo, `ai_agent_governance_patterns`, built around a
different fictional company and a broader question than this phase needs to answer on its
own. This doc applies that framing to Harborline's actual Cortex deployment rather than
re-deriving it.

## Where Harborline's dispatch assistant sits

`ai_agent_governance_patterns` follows a fictional retailer, Meridian Retail, through three
stages of AI adoption -- Crawl, Walk, and Run -- and argues that governance needs change
because what the organization is actually doing with AI changes, not on a fixed schedule.
Harborline's Cortex Agents dispatch assistant (`docs/genai/03-cortex-agents.md`) is a
Crawl-stage deployment by that framing: it answers questions against governed structured
data and unstructured documents, and it does not take any action -- it does not rebook a
shipment, message a carrier, or write anything back to a system of record. That distinction
is the whole reason this phase's governance surface stays small. A read-only assistant
giving a wrong answer is a wrong answer; a tool-calling agent taking a wrong action has a
direct operational cost. Governance sized past the actual risk is its own kind of failure,
not a safer default -- the same argument the maturity model makes for Meridian Retail's own
Crawl stage, applied here to a real deployment instead of a fictional one two layers removed.

## What Cortex gives you natively

Two properties, both already covered in `docs/genai/03-cortex-agents.md` and worth
restating here rather than re-explaining: an agent has no identity of its own, so it
authenticates and executes as whichever RBAC principal invoked it, and every privilege
boundary already built in `docs/architecture/02-security-governance-rbac.md` applies
automatically, with nothing new to grant or audit. `orchestration.budget` caps how much an
agent can spend answering a single question, a per-turn cost control in the same spirit as
the account-level resource monitor discipline in `docs/architecture/05-cost-governance.md`.

## What Cortex does not give you, and when that would start to matter

Cortex has no Snowflake-native equivalent to an Agent Registry, an Agent Gateway
intercepting and conditioning tool calls, a Model Armor-style content-filtering layer, or
continuous evaluation with automated fallback -- all real capabilities `platforms/gemini_
enterprise_governance.md` and `platforms/watsonx_governance.md` document in depth for
Meridian Retail's Walk and Run stages. That is a real gap relative to those platforms, worth
stating plainly rather than leaving implicit. It is not filled here, because Harborline's
dispatch assistant does not yet need it: nothing it does turns a bad response into a
financial or operational consequence, which is exactly the Crawl-to-Walk line the maturity
model draws. The day Harborline's agents start doing more -- rescheduling a shipment or
messaging a carrier autonomously, for instance -- is the day this phase's governance
treatment stops being sufficient, and `ai_agent_governance_patterns`' deeper frameworks
become the right next read, not an expansion of this doc.

## See also

- `ai_agent_governance_patterns` -- https://github.com/Shadoe-42/ai_agent_governance_patterns
  -- the crawl/walk/run governance maturity model, a two-way Gemini Enterprise Agent
  Platform vs. watsonx.governance comparison, and Terraform org-policy guardrails for AI
  agent workloads. Built around a different fictional company (Meridian Retail) and a
  different cloud governance surface (GCP org policy, not Snowflake RBAC) -- the maturity
  framing this doc borrows applies regardless of platform, the technical depth underneath it
  does not transfer directly and is not repeated here.
