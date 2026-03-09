variable "name" {
  description = "Name of the Bedrock knowledge base."
  type        = string
}

variable "description" {
  description = "Optional description for the knowledge base."
  type        = string
  default     = null
}

variable "role_arn" {
  description = "IAM role ARN used by the knowledge base."
  type        = string
}

variable "region" {
  description = "Optional region override for this resource."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the knowledge base resource."
  type        = map(string)
  default     = {}
}

variable "knowledge_base_type" {
  description = "Knowledge base type. Supported values in this module: VECTOR, KENDRA."
  type        = string
  default     = "VECTOR"

  validation {
    condition     = contains(["VECTOR", "KENDRA"], var.knowledge_base_type)
    error_message = "knowledge_base_type must be either VECTOR or KENDRA."
  }
}

variable "embedding_model_arn" {
  description = "Embedding model ARN for VECTOR knowledge bases."
  type        = string
  default     = null
}

variable "vector_embedding_dimensions" {
  description = "Optional embedding dimensions for VECTOR knowledge bases."
  type        = number
  default     = null
}

variable "vector_embedding_data_type" {
  description = "Optional embedding data type for VECTOR knowledge bases. Valid values: FLOAT32, BINARY."
  type        = string
  default     = null

  validation {
    condition     = var.vector_embedding_data_type == null || contains(["FLOAT32", "BINARY"], var.vector_embedding_data_type)
    error_message = "vector_embedding_data_type must be either FLOAT32 or BINARY when set."
  }
}

variable "supplemental_s3_uri" {
  description = "Optional S3 URI for supplemental data storage (for multimodal extraction). Example: s3://bucket/prefix/."
  type        = string
  default     = null
}

variable "kendra_index_arn" {
  description = "Amazon Kendra index ARN for KENDRA knowledge bases."
  type        = string
  default     = null
}

variable "vector_storage_type" {
  description = "Storage backend for VECTOR knowledge bases."
  type        = string
  default     = null
}

variable "opensearch_serverless" {
  description = "OpenSearch Serverless settings when vector_storage_type = OPENSEARCH_SERVERLESS."
  type = object({
    collection_arn    = string
    vector_index_name = string
    field_mapping = object({
      metadata_field = string
      text_field     = string
      vector_field   = string
    })
  })
  default = {
    collection_arn    = ""
    vector_index_name = ""
    field_mapping = {
      metadata_field = ""
      text_field     = ""
      vector_field   = ""
    }
  }
}

variable "opensearch_managed_cluster" {
  description = "OpenSearch managed cluster settings when vector_storage_type = OPENSEARCH_MANAGED_CLUSTER."
  type = object({
    domain_arn        = string
    domain_endpoint   = string
    vector_index_name = string
    field_mapping = object({
      metadata_field = string
      text_field     = string
      vector_field   = string
    })
  })
  default = {
    domain_arn        = ""
    domain_endpoint   = ""
    vector_index_name = ""
    field_mapping = {
      metadata_field = ""
      text_field     = ""
      vector_field   = ""
    }
  }
}

variable "s3_vectors" {
  description = "S3 Vectors settings when vector_storage_type = S3_VECTORS. Provide either index_arn, or index_name + vector_bucket_arn."
  type = object({
    index_arn         = optional(string)
    index_name        = optional(string)
    vector_bucket_arn = optional(string)
  })
  default = {}
}
