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

output "rds_cluster_arn" {
  description = "Aurora cluster ARN. Null when storage_type != RDS."
  value       = var.create_knowledge_base ? module.knowledge_base[0].rds_cluster_arn : null
}

output "rds_cluster_endpoint" {
  description = "Aurora writer endpoint. Null when storage_type != RDS."
  value       = var.create_knowledge_base ? module.knowledge_base[0].rds_cluster_endpoint : null
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Aurora master credentials. Null when storage_type != RDS."
  value       = var.create_knowledge_base ? module.knowledge_base[0].rds_secret_arn : null
}

output "redshift_namespace_arn" {
  description = "Redshift Serverless namespace ARN. Null when knowledge_base_type != SQL."
  value       = var.create_knowledge_base ? module.knowledge_base[0].redshift_namespace_arn : null
}

output "redshift_workgroup_endpoint" {
  description = "Redshift Serverless workgroup endpoint address. Null when knowledge_base_type != SQL."
  value       = var.create_knowledge_base ? module.knowledge_base[0].redshift_workgroup_endpoint : null
}

output "redshift_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Redshift admin credentials. Null when knowledge_base_type != SQL."
  value       = var.create_knowledge_base ? module.knowledge_base[0].redshift_admin_secret_arn : null
}

output "prompts" {
  description = "Map of logical key → prompt attributes (id, arn, name, version, created_at, updated_at). Empty map when create_prompt_management = false."
  value       = var.create_prompt_management ? module.prompt_management[0].prompts : {}
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

output "agent_id" {
  description = "Agent ID. Null when create_agent = false."
  value       = var.create_agent ? module.agent[0].agent_id : null
}

output "agent_arn" {
  description = "Agent ARN. Null when create_agent = false."
  value       = var.create_agent ? module.agent[0].agent_arn : null
}

output "agent_aliases" {
  description = "Map of alias key → alias attributes (agent_alias_id, agent_alias_arn). Empty map when create_agent = false."
  value       = var.create_agent ? module.agent[0].aliases : {}
}