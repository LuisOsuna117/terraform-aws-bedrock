output "id" {
  description = "Knowledge base ID."
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "arn" {
  description = "Knowledge base ARN."
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "name" {
  description = "Knowledge base name."
  value       = aws_bedrockagent_knowledge_base.this.name
}

output "created_at" {
  description = "Timestamp when the knowledge base was created."
  value       = aws_bedrockagent_knowledge_base.this.created_at
}

output "updated_at" {
  description = "Timestamp when the knowledge base was last updated."
  value       = aws_bedrockagent_knowledge_base.this.updated_at
}

# ── S3 Vectors ────────────────────────────────────────────────────────────────

output "vector_bucket_name" {
  description = "S3 Vectors bucket name. Null when storage_type != S3_VECTORS."
  value       = length(aws_s3vectors_vector_bucket.this) > 0 ? aws_s3vectors_vector_bucket.this[0].vector_bucket_name : null
}

output "vector_index_arn" {
  description = "S3 Vectors index ARN. Null when storage_type != S3_VECTORS."
  value       = length(aws_s3vectors_index.this) > 0 ? aws_s3vectors_index.this[0].index_arn : null
}

# ── OpenSearch Serverless ─────────────────────────────────────────────────────

output "opensearch_collection_arn" {
  description = "OpenSearch Serverless collection ARN. Null when storage_type != OPENSEARCH_SERVERLESS."
  value       = length(aws_opensearchserverless_collection.this) > 0 ? aws_opensearchserverless_collection.this[0].arn : null
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint. Null when storage_type != OPENSEARCH_SERVERLESS."
  value       = length(aws_opensearchserverless_collection.this) > 0 ? aws_opensearchserverless_collection.this[0].collection_endpoint : null
}

output "opensearch_index_name" {
  description = "Name of the expected vector index inside the OpenSearch Serverless collection. Null when storage_type != OPENSEARCH_SERVERLESS."
  value       = length(aws_opensearchserverless_collection.this) > 0 ? local.oss_index_name : null
}
