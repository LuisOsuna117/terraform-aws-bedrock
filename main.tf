locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-bedrock"
      ManagedBy = "Terraform"
    },
    var.tags,
  )

  knowledge_base_name = coalesce(try(var.knowledge_base_config.name, null), var.name)
  prompt_name         = coalesce(try(var.prompt_management_config.name, null), "${var.name}-prompt")
  guardrail_name      = coalesce(try(var.guardrail_config.name, null), var.name)

  prompt_bridge_prompt_arn = coalesce(
    try(var.prompt_bridge_config.existing_prompt_arn, null),
    var.create_prompt_management ? module.prompt_management[0].arn : null,
  )

  prompt_bridge_prompt_id = coalesce(
    try(var.prompt_bridge_config.existing_prompt_id, null),
    var.create_prompt_management ? module.prompt_management[0].id : null,
  )

  prompt_bridge_prompt_version = coalesce(
    try(var.prompt_bridge_config.prompt_version, null),
    var.create_prompt_management ? module.prompt_management[0].version : null,
    "DRAFT",
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !var.create_knowledge_base || var.knowledge_base_config != null
      error_message = "knowledge_base_config must be provided when create_knowledge_base = true."
    }

    precondition {
      condition     = !var.create_knowledge_base || try(trimspace(var.knowledge_base_config.role_arn) != "", false)
      error_message = "knowledge_base_config.role_arn must be set when create_knowledge_base = true."
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
      condition     = !var.create_prompt_bridge || local.prompt_bridge_prompt_id != null
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
  }
}

module "knowledge_base" {
  count  = var.create_knowledge_base ? 1 : 0
  source = "./modules/knowledge_base"

  name        = local.knowledge_base_name
  description = try(var.knowledge_base_config.description, null)
  role_arn    = var.knowledge_base_config.role_arn
  region      = try(var.knowledge_base_config.region, null)
  tags        = merge(local.common_tags, try(var.knowledge_base_config.tags, {}))

  knowledge_base_type         = try(var.knowledge_base_config.type, "VECTOR")
  embedding_model_arn         = try(var.knowledge_base_config.embedding_model_arn, null)
  vector_embedding_dimensions = try(var.knowledge_base_config.vector_embedding_dimensions, null)
  vector_embedding_data_type  = try(var.knowledge_base_config.vector_embedding_data_type, null)
  supplemental_s3_uri         = try(var.knowledge_base_config.supplemental_s3_uri, null)
  kendra_index_arn            = try(var.knowledge_base_config.kendra_index_arn, null)

  vector_storage_type = try(var.knowledge_base_config.vector_storage_type, null)
  opensearch_serverless = try(var.knowledge_base_config.opensearch_serverless, {
    collection_arn    = ""
    vector_index_name = ""
    field_mapping = {
      metadata_field = ""
      text_field     = ""
      vector_field   = ""
    }
  })
  opensearch_managed_cluster = try(var.knowledge_base_config.opensearch_managed_cluster, {
    domain_arn        = ""
    domain_endpoint   = ""
    vector_index_name = ""
    field_mapping = {
      metadata_field = ""
      text_field     = ""
      vector_field   = ""
    }
  })
  s3_vectors = try(var.knowledge_base_config.s3_vectors, {})

  depends_on = [terraform_data.validations]
}

module "prompt_management" {
  count  = var.create_prompt_management ? 1 : 0
  source = "./modules/prompt_management"

  name                        = local.prompt_name
  description                 = try(var.prompt_management_config.description, null)
  default_variant             = try(var.prompt_management_config.default_variant, null)
  customer_encryption_key_arn = try(var.prompt_management_config.customer_encryption_key_arn, null)
  region                      = try(var.prompt_management_config.region, null)
  tags                        = merge(local.common_tags, try(var.prompt_management_config.tags, {}))
  variants                    = try(var.prompt_management_config.variants, [])

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