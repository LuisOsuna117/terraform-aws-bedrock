variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-s3-vectors-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the S3 Vectors knowledge base."
  type        = string
  default     = "example-s3-vectors-kb"
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

variable "vector_embedding_dimensions" {
  description = "Embedding dimensions used by the vector model."
  type        = number
  default     = 256
}

variable "vector_embedding_data_type" {
  description = "Embedding data type for the vector model."
  type        = string
  default     = "FLOAT32"
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "knowledge-base-s3-vectors"
  }
}
