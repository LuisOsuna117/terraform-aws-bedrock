output "knowledge_base_id" {
  description = "ID of the created Redshift SQL knowledge base."
  value       = module.bedrock.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "ARN of the created Redshift SQL knowledge base."
  value       = module.bedrock.knowledge_base_arn
}

output "knowledge_base_name" {
  description = "Name of the created Redshift SQL knowledge base."
  value       = module.bedrock.knowledge_base_name
}

output "redshift_namespace_arn" {
  description = "ARN of the auto-created Redshift Serverless namespace."
  value       = module.bedrock.redshift_namespace_arn
}

output "redshift_workgroup_endpoint" {
  description = "Endpoint address of the Redshift Serverless workgroup."
  value       = module.bedrock.redshift_workgroup_endpoint
}

output "redshift_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Redshift admin credentials."
  value       = module.bedrock.redshift_admin_secret_arn
}
