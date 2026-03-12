locals {
  effective_create_knowledge_base = var.create && var.create_knowledge_base
  effective_create_guardrail      = var.create && var.create_guardrail

  knowledge_base_name = coalesce(
    try(var.knowledge_base.name, null),
    var.name,
  )

  knowledge_base_tags = merge(
    var.tags,
    try(var.knowledge_base.tags, {}),
  )

  guardrail_name = coalesce(
    try(var.guardrail.name, null),
    var.name,
  )

  guardrail_tags = merge(
    var.tags,
    try(var.guardrail.tags, {}),
  )
}

resource "terraform_data" "validation" {
  input = null

  lifecycle {
    precondition {
      condition     = !local.effective_create_knowledge_base || try(length(trimspace(local.knowledge_base_name)) > 0, false)
      error_message = "Set name or knowledge_base.name when create_knowledge_base = true."
    }

    precondition {
      condition     = !local.effective_create_guardrail || try(length(trimspace(local.guardrail_name)) > 0, false)
      error_message = "Set name or guardrail.name when create_guardrail = true."
    }
  }
}

module "knowledge_base" {
  count  = local.effective_create_knowledge_base ? 1 : 0
  source = "./modules/knowledge_base"

  create               = true
  name                 = local.knowledge_base_name
  description          = try(var.knowledge_base.description, null)
  tags                 = local.knowledge_base_tags
  create_role          = try(var.knowledge_base.create_role, true)
  create_vector_bucket = try(var.knowledge_base.create_vector_bucket, true)
  create_vector_index  = try(var.knowledge_base.create_vector_index, true)
  role_arn             = try(var.knowledge_base.role_arn, null)
  embedding_model_arn  = try(var.knowledge_base.embedding_model_arn, null)

  supplemental_data_storage_s3_uri = try(var.knowledge_base.supplemental_data_storage_s3_uri, null)
  iam_role                         = try(var.knowledge_base.iam_role, {})
  iam_role_additional_policy_documents = try(
    var.knowledge_base.iam_role_additional_policy_documents,
    [],
  )
  s3_vectors = try(var.knowledge_base.s3_vectors, {})
  timeouts   = try(var.knowledge_base.timeouts, {})

  depends_on = [terraform_data.validation]
}

module "guardrail" {
  count  = local.effective_create_guardrail ? 1 : 0
  source = "./modules/guardrail"

  create                    = true
  create_version            = try(var.guardrail.create_version, false)
  name                      = local.guardrail_name
  blocked_input_messaging   = try(var.guardrail.blocked_input_messaging, null)
  blocked_outputs_messaging = try(var.guardrail.blocked_outputs_messaging, null)
  description               = try(var.guardrail.description, null)
  kms_key_arn               = try(var.guardrail.kms_key_arn, null)
  tags                      = local.guardrail_tags
  content_policy_config     = try(var.guardrail.content_policy_config, null)
  contextual_grounding_policy_config = try(
    var.guardrail.contextual_grounding_policy_config,
    null,
  )
  cross_region_config                 = try(var.guardrail.cross_region_config, null)
  sensitive_information_policy_config = try(var.guardrail.sensitive_information_policy_config, null)
  topic_policy_config                 = try(var.guardrail.topic_policy_config, null)
  word_policy_config                  = try(var.guardrail.word_policy_config, null)
  version_description                 = try(var.guardrail.version_description, null)
  version_skip_destroy                = try(var.guardrail.version_skip_destroy, false)
  timeouts                            = try(var.guardrail.timeouts, {})
  version_timeouts                    = try(var.guardrail.version_timeouts, {})

  depends_on = [terraform_data.validation]
}
