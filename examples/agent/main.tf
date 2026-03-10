provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Bedrock Agent — complete DX example
#
# Showcases:
#   * Foundation-model agent with instruction
#   * RETURN_CONTROL action group (no Lambda required)
#   * Built-in AMAZON.UserInput action group
#   * Optional knowledge base association (set var.knowledge_base_id)
#   * Guardrail auto-wired to the agent by the root module
#   * Production alias pinned to DRAFT
# ---------------------------------------------------------------------------
module "bedrock" {
  source = "../../"

  name = var.module_name

  # ── Guardrail ──────────────────────────────────────────────────────────────
  create_guardrail = true
  guardrail_config = {
    blocked_input_messaging   = "I'm unable to process that request."
    blocked_outputs_messaging = "The response was blocked by content policy."
    description               = "Basic guardrail for the example agent."

    content_policy_config = {
      filters_config = [
        {
          type            = "HATE"
          input_strength  = "HIGH"
          output_strength = "HIGH"
        },
        {
          type            = "VIOLENCE"
          input_strength  = "MEDIUM"
          output_strength = "MEDIUM"
        },
      ]
    }
  }

  # ── Agent ──────────────────────────────────────────────────────────────────
  create_agent = true
  agent_config = {
    # guardrail_id is omitted — the root module auto-wires from create_guardrail above
    role_arn         = var.agent_role_arn
    foundation_model = var.foundation_model

    instruction = <<-EOT
      You are a helpful assistant. Answer questions concisely.
      When the user wants to look up order status, use the GetOrderStatus action.
    EOT

    description                 = "Example Bedrock agent created with terraform-aws-bedrock."
    idle_session_ttl_in_seconds = 600

    # Action groups ---------------------------------------------------------
    action_groups = {
      # RETURN_CONTROL: invoke the caller's runtime instead of a Lambda
      order_lookup = {
        description        = "Look up order status by order ID."
        action_group_state = "ENABLED"
        custom_control     = "RETURN_CONTROL"

        function_schema = {
          functions = [
            {
              name        = "GetOrderStatus"
              description = "Returns the current status of a customer order."
              parameters = [
                {
                  name        = "order_id"
                  type        = "string"
                  description = "The unique order identifier."
                  required    = true
                },
              ]
            },
          ]
        }
      }

      # Built-in AMAZON.UserInput: lets the agent ask the user for clarification
      user_input = {
        parent_action_group_signature = "AMAZON.UserInput"
        action_group_state            = "ENABLED"
      }
    }

    # Knowledge base association (only wired when knowledge_base_id is provided)
    knowledge_base_associations = var.knowledge_base_id != "" ? {
      primary = {
        knowledge_base_id    = var.knowledge_base_id
        description          = "Primary knowledge base for the example agent."
        knowledge_base_state = "ENABLED"
      }
    } : {}

    # Aliases ---------------------------------------------------------------
    aliases = {
      production = {
        description = "Stable production alias pointing at DRAFT."
        # Omit agent_version to create a floating DRAFT alias
      }
    }

    tags = var.tags
  }
}
