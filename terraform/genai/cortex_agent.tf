# Ties the semantic view and search service above together into one agent. Per
# docs/genai/03-cortex-agents.md, the agent has no identity of its own -- it runs as
# whichever RBAC principal invokes it (HARBORLINE_FR_ANALYST in the common case), so no new
# grants are needed here beyond what Cortex Analyst/Search already require on their
# underlying objects.

resource "snowflake_cortex_agent" "dispatch_assistant" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_agent_dispatch_assistant")
  comment  = "Harborline dispatch/ops assistant -- routes shipment questions to Cortex Analyst, policy/SOP questions to Cortex Search."

  profile {
    display_name = "Harborline Dispatch Assistant"
  }

  specification = <<-YAML
    orchestration:
      budget:
        seconds: 30
        tokens: 16000

    instructions:
      response: "Respond concisely, in plain language a dispatcher can act on immediately."
      orchestration: "For shipment counts, status, or weight questions, use Analyst1. For carrier contract, SOP, or incident-report questions, use Search1."
      sample_questions:
        - question: "How many shipments from the Denver facility are currently delayed?"
        - question: "What's our SOP for a refused delivery?"

    tools:
      - tool_spec:
          type: "cortex_analyst_text_to_sql"
          name: "Analyst1"
          description: "Answers shipment count, status, and weight questions against Harborline's shipment data."
      - tool_spec:
          type: "cortex_search"
          name: "Search1"
          description: "Searches Harborline carrier contracts, incident reports, and SOPs."

    tool_resources:
      Analyst1:
        semantic_view: "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_semantic_view.shipments.name}"
      Search1:
        search_service: "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_cortex_search_service.carrier_docs.name}"
        max_results: "5"
        title_column: "TITLE"
        id_column: "DOC_ID"
  YAML
}
