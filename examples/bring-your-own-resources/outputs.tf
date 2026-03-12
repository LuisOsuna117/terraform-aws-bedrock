output "knowledge_base_arn" {
  description = "ARN of the BYO Bedrock knowledge base."
  value       = module.bedrock.knowledge_base_arn
}

output "knowledge_base_role_arn" {
  description = "Role ARN used by the BYO Bedrock knowledge base."
  value       = module.bedrock.knowledge_base_role_arn
}

output "vector_index_arn" {
  description = "ARN of the BYO S3 Vectors index."
  value       = module.bedrock.knowledge_base_vector_index_arn
}
