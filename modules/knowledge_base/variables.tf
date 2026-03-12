variable "create" {
  description = "Controls whether the module creates any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the Bedrock knowledge base."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Optional description for the Bedrock knowledge base."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all managed resources. Resource-specific tags are merged on top of this map."
  type        = map(string)
  default     = {}
}

variable "create_role" {
  description = "When true, create and manage the Bedrock knowledge base IAM role and inline policy."
  type        = bool
  default     = true
}

variable "create_vector_bucket" {
  description = "When true, create the S3 Vectors vector bucket used by the knowledge base."
  type        = bool
  default     = true
}

variable "create_vector_index" {
  description = "When true, create the S3 Vectors index used by the knowledge base."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM role ARN to use when create_role = false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:", var.role_arn))
    error_message = "role_arn must be a valid ARN when set."
  }
}

variable "embedding_model_arn" {
  description = "Embedding model ARN for the vector knowledge base. Defaults to Amazon Titan Text Embeddings V2 in the current region."
  type        = string
  default     = null

  validation {
    condition     = var.embedding_model_arn == null || can(regex("^arn:", var.embedding_model_arn))
    error_message = "embedding_model_arn must be a valid ARN when set."
  }
}

variable "supplemental_data_storage_s3_uri" {
  description = "Optional S3 URI for supplemental multimodal data storage."
  type        = string
  default     = null

  validation {
    condition     = var.supplemental_data_storage_s3_uri == null || can(regex("^s3://", var.supplemental_data_storage_s3_uri))
    error_message = "supplemental_data_storage_s3_uri must start with s3:// when set."
  }
}

variable "iam_role" {
  description = "Advanced IAM role settings used when create_role = true."
  type = object({
    name                 = optional(string)
    description          = optional(string)
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    max_session_duration = optional(number, 3600)
    tags                 = optional(map(string), {})
  })
  default = {}

  validation {
    condition     = try(var.iam_role.permissions_boundary, null) == null || can(regex("^arn:", var.iam_role.permissions_boundary))
    error_message = "iam_role.permissions_boundary must be a valid ARN when set."
  }

  validation {
    condition     = try(var.iam_role.max_session_duration, 3600) >= 3600 && try(var.iam_role.max_session_duration, 3600) <= 43200
    error_message = "iam_role.max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "iam_role_additional_policy_documents" {
  description = "Additional IAM policy documents, as JSON strings, merged into the managed inline policy. Useful for future data source permissions."
  type        = list(string)
  default     = []
}

variable "s3_vectors" {
  description = "S3 Vectors settings for the knowledge base. Common-path users typically only set dimension overrides here."
  type = object({
    vector_bucket_arn  = optional(string)
    vector_bucket_name = optional(string)
    index_arn          = optional(string)
    index_name         = optional(string)
    dimension          = optional(number, 1024)
    distance_metric    = optional(string, "cosine")
    data_type          = optional(string, "float32")
    force_destroy      = optional(bool, false)
    non_filterable_metadata_keys = optional(list(string), [
      "AMAZON_BEDROCK_TEXT",
      "AMAZON_BEDROCK_METADATA",
    ])
    bucket_encryption = optional(object({
      sse_type    = optional(string, "AES256")
      kms_key_arn = optional(string)
    }))
    index_encryption = optional(object({
      sse_type    = optional(string, "AES256")
      kms_key_arn = optional(string)
    }))
    tags = optional(map(string), {})
  })
  default = {}

  validation {
    condition = (
      try(var.s3_vectors.vector_bucket_arn, null) == null ||
      can(regex("^arn:", var.s3_vectors.vector_bucket_arn))
      ) && (
      try(var.s3_vectors.index_arn, null) == null ||
      can(regex("^arn:", var.s3_vectors.index_arn))
    )
    error_message = "s3_vectors.vector_bucket_arn and s3_vectors.index_arn must be valid ARNs when set."
  }

  validation {
    condition     = try(var.s3_vectors.dimension, 1024) >= 1 && try(var.s3_vectors.dimension, 1024) <= 4096
    error_message = "s3_vectors.dimension must be between 1 and 4096."
  }

  validation {
    condition     = contains(["cosine", "euclidean"], lower(try(var.s3_vectors.distance_metric, "cosine")))
    error_message = "s3_vectors.distance_metric must be one of: cosine, euclidean."
  }

  validation {
    condition     = lower(try(var.s3_vectors.data_type, "float32")) == "float32"
    error_message = "s3_vectors.data_type must be float32 for S3 Vectors."
  }

  validation {
    condition = (
      length(try(var.s3_vectors.non_filterable_metadata_keys, [])) <= 10 &&
      length(distinct(try(var.s3_vectors.non_filterable_metadata_keys, []))) == length(try(var.s3_vectors.non_filterable_metadata_keys, [])) &&
      alltrue([
        for key in try(var.s3_vectors.non_filterable_metadata_keys, []) :
        length(key) >= 1 && length(key) <= 63
      ])
    )
    error_message = "s3_vectors.non_filterable_metadata_keys must contain at most 10 unique keys and each key must be 1-63 characters long."
  }

  validation {
    condition = (
      try(var.s3_vectors.bucket_encryption, null) == null ||
      contains(["AES256", "aws:kms"], try(var.s3_vectors.bucket_encryption.sse_type, "AES256"))
      ) && (
      try(var.s3_vectors.index_encryption, null) == null ||
      contains(["AES256", "aws:kms"], try(var.s3_vectors.index_encryption.sse_type, "AES256"))
    )
    error_message = "s3_vectors bucket and index encryption sse_type values must be AES256 or aws:kms."
  }

  validation {
    condition = (
      try(var.s3_vectors.bucket_encryption, null) == null ||
      try(var.s3_vectors.bucket_encryption.sse_type, "AES256") != "aws:kms" ||
      try(var.s3_vectors.bucket_encryption.kms_key_arn, null) != null
      ) && (
      try(var.s3_vectors.index_encryption, null) == null ||
      try(var.s3_vectors.index_encryption.sse_type, "AES256") != "aws:kms" ||
      try(var.s3_vectors.index_encryption.kms_key_arn, null) != null
    )
    error_message = "Provide kms_key_arn whenever a bucket or index encryption sse_type is aws:kms."
  }
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for aws_bedrockagent_knowledge_base."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
