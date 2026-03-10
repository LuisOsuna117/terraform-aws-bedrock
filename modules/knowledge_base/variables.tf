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
  description = "Knowledge base type. Supported values: VECTOR, KENDRA."
  type        = string
  default     = "VECTOR"

  validation {
    condition     = contains(["VECTOR", "KENDRA"], var.knowledge_base_type)
    error_message = "knowledge_base_type must be either VECTOR or KENDRA."
  }
}

variable "vector_config" {
  description = <<-EOT
    Configuration for VECTOR knowledge bases. Required when knowledge_base_type = VECTOR.

    embedding_model_arn         - ARN of the Bedrock embedding model (required)
    vector_embedding_dimensions - Optional dimensions override
    vector_embedding_data_type  - FLOAT32 or BINARY
    supplemental_s3_uri         - S3 URI for supplemental multimodal data
    storage_type                - OPENSEARCH_SERVERLESS | OPENSEARCH_MANAGED_CLUSTER | S3_VECTORS
    opensearch_serverless       - Required when storage_type = OPENSEARCH_SERVERLESS
    opensearch_managed_cluster  - Required when storage_type = OPENSEARCH_MANAGED_CLUSTER
    s3_vectors                  - Required when storage_type = S3_VECTORS
  EOT
  type = object({
    embedding_model_arn         = string
    vector_embedding_dimensions = optional(number)
    vector_embedding_data_type  = optional(string)
    supplemental_s3_uri         = optional(string)
    storage_type                = string

    opensearch_serverless = optional(object({
      collection_arn    = string
      vector_index_name = string
      field_mapping = object({
        metadata_field = string
        text_field     = string
        vector_field   = string
      })
    }))

    opensearch_managed_cluster = optional(object({
      domain_arn        = string
      domain_endpoint   = string
      vector_index_name = string
      field_mapping = object({
        metadata_field = string
        text_field     = string
        vector_field   = string
      })
    }))

    s3_vectors = optional(object({
      index_arn         = optional(string)
      index_name        = optional(string)
      vector_bucket_arn = optional(string)
    }), {})
  })
  default = null

  validation {
    condition = var.vector_config == null || contains(
      ["OPENSEARCH_SERVERLESS", "OPENSEARCH_MANAGED_CLUSTER", "S3_VECTORS"],
      var.vector_config.storage_type
    )
    error_message = "vector_config.storage_type must be OPENSEARCH_SERVERLESS, OPENSEARCH_MANAGED_CLUSTER, or S3_VECTORS."
  }

  validation {
    condition = var.vector_config == null || (
      var.vector_config.vector_embedding_data_type == null ||
      contains(["FLOAT32", "BINARY"], var.vector_config.vector_embedding_data_type)
    )
    error_message = "vector_config.vector_embedding_data_type must be FLOAT32 or BINARY when set."
  }
}

variable "kendra_config" {
  description = "Configuration for KENDRA knowledge bases. Required when knowledge_base_type = KENDRA."
  type = object({
    kendra_index_arn = string
  })
  default = null
}
