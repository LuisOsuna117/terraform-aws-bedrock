output "knowledge_base_arn" {
  description = "ARN of the Bedrock knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].knowledge_base_arn, null)
}

output "knowledge_base_id" {
  description = "ID of the Bedrock knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].knowledge_base_id, null)
}

output "knowledge_base_name" {
  description = "Name of the Bedrock knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].knowledge_base_name, null)
}

output "knowledge_base_role_arn" {
  description = "Role ARN used by the Bedrock knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].knowledge_base_role_arn, null)
}

output "knowledge_base_embedding_model_arn" {
  description = "Embedding model ARN used by the Bedrock knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].embedding_model_arn, null)
}

output "knowledge_base_vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket backing the knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].vector_bucket_arn, null)
}

output "knowledge_base_vector_bucket_name" {
  description = "Name of the S3 Vectors bucket backing the knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].vector_bucket_name, null)
}

output "knowledge_base_vector_index_arn" {
  description = "ARN of the S3 Vectors index backing the knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].vector_index_arn, null)
}

output "knowledge_base_vector_index_name" {
  description = "Name of the S3 Vectors index backing the knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].vector_index_name, null)
}

output "knowledge_base_vector_dimension" {
  description = "Vector dimension configured for the knowledge base. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].vector_dimension, null)
}

output "knowledge_base_distance_metric" {
  description = "Distance metric configured for the knowledge base S3 Vectors index. Null when create_knowledge_base = false."
  value       = try(module.knowledge_base[0].distance_metric, null)
}

output "knowledge_base_managed_role_arn" {
  description = "ARN of the managed IAM role created by the knowledge base submodule. Null when no managed role is created."
  value       = try(module.knowledge_base[0].iam_role_arn, null)
}

output "knowledge_base_managed_role_name" {
  description = "Name of the managed IAM role created by the knowledge base submodule. Null when no managed role is created."
  value       = try(module.knowledge_base[0].iam_role_name, null)
}

output "guardrail_id" {
  description = "Guardrail ID. Null when create_guardrail = false."
  value       = try(module.guardrail[0].guardrail_id, null)
}

output "guardrail_arn" {
  description = "Guardrail ARN. Null when create_guardrail = false."
  value       = try(module.guardrail[0].guardrail_arn, null)
}

output "guardrail_status" {
  description = "Guardrail status. Null when create_guardrail = false."
  value       = try(module.guardrail[0].status, null)
}

output "guardrail_draft_version" {
  description = "Draft version reported by aws_bedrock_guardrail. Null when create_guardrail = false."
  value       = try(module.guardrail[0].draft_version, null)
}

output "guardrail_published_version" {
  description = "Published version created by aws_bedrock_guardrail_version. Null when no version is created."
  value       = try(module.guardrail[0].published_version, null)
}

output "guardrail_created_at" {
  description = "Unix epoch timestamp in seconds for when the guardrail was created. Null when create_guardrail = false."
  value       = try(module.guardrail[0].created_at, null)
}
