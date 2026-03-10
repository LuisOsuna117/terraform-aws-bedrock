locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-bedrock"
      ManagedBy = "Terraform"
    },
    var.tags,
  )

  knowledge_base_name = coalesce(var.knowledge_base_name, var.name)
  guardrail_name      = coalesce(try(var.guardrail_config.name, null), var.name)
  agent_name          = coalesce(try(var.agent_config.name, null), var.name)

  # Resolve the target prompt from the managed module for the bridge.
  # Use prompt_bridge_config.prompt_key when multiple prompts are present;
  # otherwise fall back to the first entry in the map.
  _bridge_prompt_key = try(var.prompt_bridge_config.prompt_key, null)
  _bridge_managed_prompt = var.create_prompt_management ? (
    local._bridge_prompt_key != null
    ? module.prompt_management[0].prompts[local._bridge_prompt_key]
    : values(module.prompt_management[0].prompts)[0]
  ) : null

  prompt_bridge_prompt_arn = (
    try(var.prompt_bridge_config.existing_prompt_arn, null) != null
    ? var.prompt_bridge_config.existing_prompt_arn
    : try(local._bridge_managed_prompt.arn, null)
  )

  prompt_bridge_prompt_id = (
    try(var.prompt_bridge_config.existing_prompt_id, null) != null
    ? var.prompt_bridge_config.existing_prompt_id
    : try(local._bridge_managed_prompt.id, null)
  )

  prompt_bridge_prompt_version = coalesce(
    try(var.prompt_bridge_config.prompt_version, null),
    try(local._bridge_managed_prompt.version, null),
    "DRAFT",
  )

  # Auto-wire the sibling guardrail module's ID to the agent unless explicitly overridden.
  agent_guardrail_id = (
    try(var.agent_config.guardrail_id, null) != null
    ? var.agent_config.guardrail_id
    : var.create_guardrail ? module.guardrail[0].guardrail_id : null
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !var.create_knowledge_base || try(trimspace(var.knowledge_base_role_arn) != "", false)
      error_message = "knowledge_base_role_arn must be set when create_knowledge_base = true."
    }

    precondition {
      condition     = !var.create_prompt_management || var.prompt_management_config != null
      error_message = "prompt_management_config must be provided when create_prompt_management = true."
    }

    precondition {
      condition     = !var.create_prompt_bridge || var.prompt_bridge_config != null
      error_message = "prompt_bridge_config must be provided when create_prompt_bridge = true."
    }

    precondition {
      condition = !var.create_prompt_bridge || (
        var.create_prompt_management || try(trimspace(var.prompt_bridge_config.existing_prompt_id) != "", false)
      )
      error_message = "Prompt bridge requires a prompt ID. Set create_prompt_management = true or provide prompt_bridge_config.existing_prompt_id."
    }

    precondition {
      condition     = !var.create_guardrail || var.guardrail_config != null
      error_message = "guardrail_config must be provided when create_guardrail = true."
    }

    precondition {
      condition     = !var.create_guardrail || try(trimspace(var.guardrail_config.blocked_input_messaging) != "", false)
      error_message = "guardrail_config.blocked_input_messaging must be set when create_guardrail = true."
    }

    precondition {
      condition     = !var.create_guardrail || try(trimspace(var.guardrail_config.blocked_outputs_messaging) != "", false)
      error_message = "guardrail_config.blocked_outputs_messaging must be set when create_guardrail = true."
    }

    precondition {
      condition     = !var.create_agent || var.agent_config != null
      error_message = "agent_config must be provided when create_agent = true."
    }

    precondition {
      condition     = !var.create_agent || try(trimspace(var.agent_config.role_arn) != "", false)
      error_message = "agent_config.role_arn must be set when create_agent = true."
    }

    precondition {
      condition     = !var.create_agent || try(trimspace(var.agent_config.foundation_model) != "", false)
      error_message = "agent_config.foundation_model must be set when create_agent = true."
    }
  }
}

module "knowledge_base" {
  count  = var.create_knowledge_base ? 1 : 0
  source = "./modules/knowledge_base"

  name        = local.knowledge_base_name
  description = var.knowledge_base_description
  role_arn    = var.knowledge_base_role_arn
  region      = var.knowledge_base_region
  tags        = merge(local.common_tags, var.knowledge_base_tags)

  knowledge_base_type         = var.knowledge_base_type
  embedding_model_arn         = var.embedding_model_arn
  vector_embedding_dimensions = var.vector_embedding_dimensions
  vector_embedding_data_type  = var.vector_embedding_data_type
  supplemental_s3_uri         = var.supplemental_s3_uri
  storage_type                = var.storage_type
  opensearch_serverless       = var.opensearch_serverless
  opensearch_managed_cluster  = var.opensearch_managed_cluster
  s3_vectors                  = var.s3_vectors
  rds                         = var.rds
  kendra_index_arn            = var.kendra_index_arn
  redshift                    = var.redshift

  depends_on = [terraform_data.validations]
}

module "prompt_management" {
  count  = var.create_prompt_management ? 1 : 0
  source = "./modules/prompt_management"

  tags    = merge(local.common_tags, try(var.prompt_management_config.tags, {}))
  prompts = try(var.prompt_management_config.prompts, {})

  depends_on = [terraform_data.validations]
}

module "guardrail" {
  count  = var.create_guardrail ? 1 : 0
  source = "./modules/guardrail"

  name                      = local.guardrail_name
  blocked_input_messaging   = var.guardrail_config.blocked_input_messaging
  blocked_outputs_messaging = var.guardrail_config.blocked_outputs_messaging
  description               = try(var.guardrail_config.description, null)
  kms_key_arn               = try(var.guardrail_config.kms_key_arn, null)
  region                    = try(var.guardrail_config.region, null)
  tags                      = merge(local.common_tags, try(var.guardrail_config.tags, {}))

  content_policy_config               = try(var.guardrail_config.content_policy_config, null)
  contextual_grounding_policy_config  = try(var.guardrail_config.contextual_grounding_policy_config, null)
  cross_region_config                 = try(var.guardrail_config.cross_region_config, null)
  sensitive_information_policy_config = try(var.guardrail_config.sensitive_information_policy_config, null)
  topic_policy_config                 = try(var.guardrail_config.topic_policy_config, null)
  word_policy_config                  = try(var.guardrail_config.word_policy_config, null)

  depends_on = [terraform_data.validations]
}

module "agent" {
  count  = var.create_agent ? 1 : 0
  source = "./modules/agent"

  name             = local.agent_name
  role_arn         = var.agent_config.role_arn
  foundation_model = var.agent_config.foundation_model

  instruction                 = try(var.agent_config.instruction, null)
  description                 = try(var.agent_config.description, null)
  idle_session_ttl_in_seconds = try(var.agent_config.idle_session_ttl_in_seconds, 600)
  agent_collaboration         = try(var.agent_config.agent_collaboration, "DISABLED")
  customer_encryption_key_arn = try(var.agent_config.customer_encryption_key_arn, null)
  prepare_agent               = try(var.agent_config.prepare_agent, true)
  skip_resource_in_use_check  = try(var.agent_config.skip_resource_in_use_check, false)
  region                      = try(var.agent_config.region, null)
  tags                        = merge(local.common_tags, try(var.agent_config.tags, {}))

  guardrail_id      = local.agent_guardrail_id
  guardrail_version = try(var.agent_config.guardrail_version, "DRAFT")

  memory_configuration        = try(var.agent_config.memory_configuration, null)
  action_groups               = try(var.agent_config.action_groups, {})
  knowledge_base_associations = try(var.agent_config.knowledge_base_associations, {})
  aliases                     = try(var.agent_config.aliases, {})
  collaborators               = try(var.agent_config.collaborators, {})

  depends_on = [terraform_data.validations]
}