variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-os-managed-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the OpenSearch Managed Cluster knowledge base."
  type        = string
  default     = "example-os-managed-kb"
}

variable "knowledge_base_role_arn" {
  description = "IAM role ARN used by the knowledge base."
  type        = string
  default     = "arn:aws:iam::123456789012:role/bedrock-kb-role"
}

variable "embedding_model_arn" {
  description = "Embedding model ARN for the vector knowledge base."
  type        = string
  default     = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}

variable "vector_embedding_data_type" {
  description = "Embedding data type for the vector model."
  type        = string
  default     = "FLOAT32"
}

variable "domain_arn" {
  description = "OpenSearch domain ARN."
  type        = string
  default     = "arn:aws:es:us-east-1:123456789012:domain/example-domain"
}

variable "domain_endpoint" {
  description = "OpenSearch domain endpoint URL."
  type        = string
  default     = "https://search-example-domain.us-east-1.es.amazonaws.com"
}

variable "vector_index_name" {
  description = "Vector index name used in the OpenSearch domain."
  type        = string
  default     = "example-index"
}

variable "metadata_field" {
  description = "Metadata field mapping name."
  type        = string
  default     = "metadata"
}

variable "text_field" {
  description = "Text field mapping name."
  type        = string
  default     = "chunks"
}

variable "vector_field" {
  description = "Vector field mapping name."
  type        = string
  default     = "embedding"
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "knowledge-base-opensearch-managed-cluster"
  }
}
