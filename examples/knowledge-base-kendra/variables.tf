variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-kendra-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the Kendra-backed knowledge base."
  type        = string
  default     = "example-kendra-kb"
}

variable "knowledge_base_role_arn" {
  description = "IAM role ARN used by the knowledge base."
  type        = string
  default     = "arn:aws:iam::123456789012:role/bedrock-kb-role"
}

variable "kendra_index_arn" {
  description = "Amazon Kendra index ARN used by the knowledge base."
  type        = string
  default     = "arn:aws:kendra:us-east-1:123456789012:index/example-index-id"
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "knowledge-base-kendra"
  }
}
