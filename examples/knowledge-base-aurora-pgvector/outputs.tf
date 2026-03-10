output "knowledge_base_id" {
  description = "ID of the created Aurora pgvector knowledge base."
  value       = module.bedrock.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "ARN of the created Aurora pgvector knowledge base."
  value       = module.bedrock.knowledge_base_arn
}

output "knowledge_base_name" {
  description = "Name of the created Aurora pgvector knowledge base."
  value       = module.bedrock.knowledge_base_name
}

output "rds_cluster_arn" {
  description = "ARN of the auto-created Aurora Serverless v2 cluster."
  value       = module.bedrock.rds_cluster_arn
}

output "rds_cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster."
  value       = module.bedrock.rds_cluster_endpoint
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Aurora master credentials."
  value       = module.bedrock.rds_secret_arn
}
