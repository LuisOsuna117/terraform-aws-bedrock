resource "aws_bedrockagent_agent" "this" {
  agent_name                  = var.name
  agent_resource_role_arn     = var.role_arn
  foundation_model            = var.foundation_model
  instruction                 = var.instruction
  description                 = var.description
  idle_session_ttl_in_seconds = var.idle_session_ttl_in_seconds
  agent_collaboration         = var.agent_collaboration
  customer_encryption_key_arn = var.customer_encryption_key_arn
  prepare_agent               = var.prepare_agent
  skip_resource_in_use_check  = var.skip_resource_in_use_check
  region                      = var.region
  tags                        = var.tags

  dynamic "guardrail_configuration" {
    for_each = var.guardrail_id != null ? [1] : []
    content {
      guardrail_identifier = var.guardrail_id
      guardrail_version    = coalesce(var.guardrail_version, "DRAFT")
    }
  }

  dynamic "memory_configuration" {
    for_each = var.memory_configuration != null ? [var.memory_configuration] : []
    content {
      enabled_memory_types = memory_configuration.value.enabled_memory_types
      storage_days         = try(memory_configuration.value.storage_days, null)

      dynamic "session_summary_configuration" {
        for_each = try(memory_configuration.value.max_recent_sessions, null) != null ? [memory_configuration.value.max_recent_sessions] : []
        content {
          max_recent_sessions = session_summary_configuration.value
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Action groups
# ---------------------------------------------------------------------------
resource "aws_bedrockagent_agent_action_group" "this" {
  for_each = var.action_groups

  action_group_name             = try(each.value.name, each.key)
  agent_id                      = aws_bedrockagent_agent.this.agent_id
  agent_version                 = "DRAFT"
  description                   = try(each.value.parent_action_group_signature, null) == "AMAZON.UserInput" ? null : try(each.value.description, null)
  action_group_state            = try(each.value.action_group_state, "ENABLED")
  parent_action_group_signature = try(each.value.parent_action_group_signature, null)
  prepare_agent                 = try(each.value.prepare_agent, true)
  skip_resource_in_use_check    = try(each.value.skip_resource_in_use_check, true)
  region                        = try(each.value.region, null)

  # Required except for AMAZON.UserInput built-in
  dynamic "action_group_executor" {
    for_each = try(each.value.parent_action_group_signature, null) != "AMAZON.UserInput" ? [1] : []
    content {
      lambda         = try(each.value.lambda_arn, null)
      custom_control = try(each.value.custom_control, null)
    }
  }

  # OpenAPI schema (payload string or S3 reference)
  dynamic "api_schema" {
    for_each = (
      try(each.value.parent_action_group_signature, null) != "AMAZON.UserInput" &&
      (try(each.value.api_schema_payload, null) != null || try(each.value.api_schema_s3_bucket, null) != null)
    ) ? [1] : []
    content {
      payload = try(each.value.api_schema_payload, null)
      dynamic "s3" {
        for_each = try(each.value.api_schema_s3_bucket, null) != null ? [1] : []
        content {
          s3_bucket_name = each.value.api_schema_s3_bucket
          s3_object_key  = try(each.value.api_schema_s3_key, null)
        }
      }
    }
  }

  # Simplified function schema
  dynamic "function_schema" {
    for_each = try(each.value.function_schema, null) != null ? [each.value.function_schema] : []
    content {
      member_functions {
        dynamic "functions" {
          for_each = try(function_schema.value.functions, [])
          content {
            name        = functions.value.name
            description = try(functions.value.description, null)
            dynamic "parameters" {
              for_each = try(functions.value.parameters, [])
              content {
                map_block_key = parameters.value.name
                type          = parameters.value.type
                description   = try(parameters.value.description, null)
                required      = try(parameters.value.required, null)
              }
            }
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Knowledge base associations
# ---------------------------------------------------------------------------
resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  for_each = var.knowledge_base_associations

  agent_id             = aws_bedrockagent_agent.this.agent_id
  agent_version        = "DRAFT"
  description          = each.value.description
  knowledge_base_id    = each.value.knowledge_base_id
  knowledge_base_state = try(each.value.knowledge_base_state, "ENABLED")
  region               = try(each.value.region, null)
}

# ---------------------------------------------------------------------------
# Agent aliases  – depend on all mutations that require a prepare cycle
# ---------------------------------------------------------------------------
resource "aws_bedrockagent_agent_alias" "this" {
  for_each = var.aliases

  agent_alias_name = try(each.value.name, each.key)
  agent_id         = aws_bedrockagent_agent.this.agent_id
  description      = try(each.value.description, null)
  region           = try(each.value.region, null)
  tags             = merge(var.tags, try(each.value.tags, {}))

  dynamic "routing_configuration" {
    for_each = try(each.value.agent_version, null) != null ? [each.value] : []
    content {
      agent_version          = routing_configuration.value.agent_version
      provisioned_throughput = try(routing_configuration.value.provisioned_throughput, null)
    }
  }

  depends_on = [
    aws_bedrockagent_agent_action_group.this,
    aws_bedrockagent_agent_knowledge_base_association.this,
  ]
}

# ---------------------------------------------------------------------------
# Sub-agent collaborators (supervisor/supervisor-router agents only)
# ---------------------------------------------------------------------------
resource "aws_bedrockagent_agent_collaborator" "this" {
  for_each = var.collaborators

  agent_id                   = aws_bedrockagent_agent.this.agent_id
  collaborator_name          = try(each.value.name, each.key)
  collaboration_instruction  = each.value.collaboration_instruction
  relay_conversation_history = try(each.value.relay_conversation_history, null)
  prepare_agent              = try(each.value.prepare_agent, true)
  region                     = try(each.value.region, null)

  agent_descriptor {
    alias_arn = each.value.alias_arn
  }
}
