output "knowledge_base_arn" {
  description = "ARN of the Bedrock knowledge base."
  value       = try(aws_bedrockagent_knowledge_base.this[0].arn, null)
}

output "knowledge_base_id" {
  description = "ID of the Bedrock knowledge base."
  value       = try(aws_bedrockagent_knowledge_base.this[0].id, null)
}

output "knowledge_base_name" {
  description = "Name of the Bedrock knowledge base."
  value       = try(aws_bedrockagent_knowledge_base.this[0].name, null)
}

output "knowledge_base_role_arn" {
  description = "IAM role ARN used by the Bedrock knowledge base."
  value       = local.resolved_role_arn
}

output "embedding_model_arn" {
  description = "Embedding model ARN used by the Bedrock knowledge base."
  value       = local.resolved_embedding_model_arn
}

output "vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket backing the knowledge base."
  value       = local.resolved_vector_bucket_arn
}

output "vector_bucket_name" {
  description = "Name of the S3 Vectors bucket backing the knowledge base."
  value       = local.resolved_vector_bucket_name
}

output "vector_index_arn" {
  description = "ARN of the S3 Vectors index backing the knowledge base."
  value       = local.resolved_vector_index_arn
}

output "vector_index_name" {
  description = "Name of the S3 Vectors index backing the knowledge base."
  value       = local.resolved_vector_index_name
}

output "vector_dimension" {
  description = "Vector dimension configured for the knowledge base and S3 Vectors index."
  value       = local.resolved_dimension
}

output "distance_metric" {
  description = "Distance metric configured for the S3 Vectors index."
  value       = local.resolved_distance_metric
}

output "iam_role_arn" {
  description = "ARN of the managed IAM role. Null when create_role = false."
  value       = try(aws_iam_role.this[0].arn, null)
}

output "iam_role_name" {
  description = "Name of the managed IAM role. Null when create_role = false."
  value       = try(aws_iam_role.this[0].name, null)
}
