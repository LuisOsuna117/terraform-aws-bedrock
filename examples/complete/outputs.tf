output "knowledge_base_arn" {
  description = "ARN of the managed Bedrock knowledge base."
  value       = module.bedrock.knowledge_base_arn
}

output "vector_bucket_name" {
  description = "Name of the managed S3 Vectors bucket."
  value       = module.bedrock.knowledge_base_vector_bucket_name
}

output "vector_index_name" {
  description = "Name of the managed S3 Vectors index."
  value       = module.bedrock.knowledge_base_vector_index_name
}
