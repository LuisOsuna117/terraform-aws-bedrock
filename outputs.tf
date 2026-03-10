output "knowledge_base_id" {
  description = "Knowledge base ID. Null when create_knowledge_base = false."
  value       = var.create_knowledge_base ? module.knowledge_base[0].id : null
}

output "knowledge_base_arn" {
  description = "Knowledge base ARN. Null when create_knowledge_base = false."
  value       = var.create_knowledge_base ? module.knowledge_base[0].arn : null
}

output "knowledge_base_name" {
  description = "Knowledge base name. Null when create_knowledge_base = false."
  value       = var.create_knowledge_base ? module.knowledge_base[0].name : null
}

output "prompt_id" {
  description = "Prompt ID. Null when create_prompt_management = false."
  value       = var.create_prompt_management ? module.prompt_management[0].id : null
}

output "prompt_arn" {
  description = "Prompt ARN. Null when create_prompt_management = false."
  value       = var.create_prompt_management ? module.prompt_management[0].arn : null
}

output "prompt_name" {
  description = "Prompt name. Null when create_prompt_management = false."
  value       = var.create_prompt_management ? module.prompt_management[0].name : null
}

output "prompt_version" {
  description = "Prompt version (DRAFT on create). Null when create_prompt_management = false."
  value       = var.create_prompt_management ? module.prompt_management[0].version : null
}

output "prompt_bridge_prompt_id" {
  description = "Resolved prompt ID for bridge consumers. Null when create_prompt_bridge = false."
  value       = var.create_prompt_bridge ? local.prompt_bridge_prompt_id : null
}

output "prompt_bridge_prompt_arn" {
  description = "Resolved prompt ARN for bridge consumers. Null when create_prompt_bridge = false."
  value       = var.create_prompt_bridge ? local.prompt_bridge_prompt_arn : null
}

output "prompt_bridge_prompt_version" {
  description = "Resolved prompt version for bridge consumers. Null when create_prompt_bridge = false."
  value       = var.create_prompt_bridge ? local.prompt_bridge_prompt_version : null
}

output "prompt_bridge_environment_variables" {
  description = "Environment variable map for application runtimes (for example AgentCore containers) to consume Bedrock prompt references. Null when create_prompt_bridge = false."
  value = var.create_prompt_bridge ? {
    (try(var.prompt_bridge_config.env_var_names.prompt_id, "BEDROCK_PROMPT_ID"))           = local.prompt_bridge_prompt_id
    (try(var.prompt_bridge_config.env_var_names.prompt_arn, "BEDROCK_PROMPT_ARN"))         = local.prompt_bridge_prompt_arn
    (try(var.prompt_bridge_config.env_var_names.prompt_version, "BEDROCK_PROMPT_VERSION")) = local.prompt_bridge_prompt_version
  } : null
}

output "guardrail_id" {
  description = "Guardrail ID. Null when create_guardrail = false."
  value       = var.create_guardrail ? module.guardrail[0].guardrail_id : null
}

output "guardrail_arn" {
  description = "Guardrail ARN. Null when create_guardrail = false."
  value       = var.create_guardrail ? module.guardrail[0].guardrail_arn : null
}

output "guardrail_version" {
  description = "Guardrail version. Null when create_guardrail = false."
  value       = var.create_guardrail ? module.guardrail[0].version : null
}

output "guardrail_status" {
  description = "Guardrail status. Null when create_guardrail = false."
  value       = var.create_guardrail ? module.guardrail[0].status : null
}