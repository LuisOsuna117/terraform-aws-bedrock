variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-redshift-kb"
}

variable "knowledge_base_name" {
  description = "Explicit name for the Redshift SQL knowledge base."
  type        = string
  default     = "example-redshift-kb"
}

variable "knowledge_base_role_arn" {
  description = "IAM role ARN used by the knowledge base. The role must have redshift-serverless:GetCredentials and redshift-data:BatchExecuteStatement (plus DescribeStatement, GetStatementResult) permissions on the workgroup."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Redshift Serverless workgroup will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the Redshift Serverless workgroup (minimum 3 AZs recommended)."
  type        = list(string)
}

variable "namespace_name" {
  description = "Optional Redshift Serverless namespace name. Defaults to var.module_name."
  type        = string
  default     = null
}

variable "workgroup_name" {
  description = "Optional Redshift Serverless workgroup name. Defaults to var.module_name."
  type        = string
  default     = null
}

variable "database_name" {
  description = "Initial database name to create in the namespace."
  type        = string
  default     = "bedrock_kb"
}

variable "base_capacity" {
  description = "Redshift Processing Units (RPUs) for the workgroup (default 8 = minimum)."
  type        = number
  default     = 8
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to Redshift on port 5439."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to Redshift on port 5439."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
