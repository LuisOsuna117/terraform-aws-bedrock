variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-aurora-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the Aurora pgvector knowledge base."
  type        = string
  default     = "example-aurora-kb"
}

variable "knowledge_base_role_arn" {
  description = "IAM role ARN used by the knowledge base. The role must have rds-data:ExecuteStatement, rds-data:BatchExecuteStatement, and secretsmanager:GetSecretValue permissions on the cluster and credential secret."
  type        = string
}

variable "embedding_model_arn" {
  description = "Embedding model ARN. Dimensions must match the vector column created in the DB."
  type        = string
  default     = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}

variable "vector_embedding_dimensions" {
  description = "Number of dimensions for the embedding model (used only for the KB configuration description)."
  type        = number
  default     = 1024
}

variable "vpc_id" {
  description = "VPC ID where the Aurora cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the Aurora DB subnet group (minimum 2 AZs)."
  type        = list(string)
}

variable "cluster_identifier" {
  description = "Optional Aurora cluster identifier. Defaults to var.module_name."
  type        = string
  default     = null
}

variable "database_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "bedrock_kb"
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to Aurora on port 5432. Empty = no direct network access (Bedrock uses RDS Data API — no inbound rule required)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to Aurora on port 5432."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
