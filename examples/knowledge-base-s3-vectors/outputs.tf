output "knowledge_base_id" {
  description = "ID of the created S3 Vectors knowledge base."
  value       = module.bedrock.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "ARN of the created S3 Vectors knowledge base."
  value       = module.bedrock.knowledge_base_arn
}

output "knowledge_base_name" {
  description = "Name of the created S3 Vectors knowledge base."
  value       = module.bedrock.knowledge_base_name
}
