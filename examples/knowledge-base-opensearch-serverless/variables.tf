variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-os-serverless-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the OpenSearch Serverless knowledge base."
  type        = string
  default     = "example-os-serverless-kb"
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

variable "vector_index_name" {
  description = "Vector index name used in OpenSearch Serverless."
  type        = string
  default     = "bedrock-kb-index"
}

variable "metadata_field" {
  description = "Metadata field mapping name."
  type        = string
  default     = "AMAZON_BEDROCK_METADATA"
}

variable "text_field" {
  description = "Text field mapping name."
  type        = string
  default     = "AMAZON_BEDROCK_TEXT_CHUNK"
}

variable "vector_field" {
  description = "Vector field mapping name."
  type        = string
  default     = "bedrock-knowledge-base-default-vector"
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "knowledge-base-opensearch-serverless"
  }
}
