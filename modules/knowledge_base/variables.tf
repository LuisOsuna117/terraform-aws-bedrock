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
  description = "Knowledge base type. Supported values: VECTOR, KENDRA, SQL."
  type        = string
  default     = "VECTOR"

  validation {
    condition     = contains(["VECTOR", "KENDRA", "SQL"], var.knowledge_base_type)
    error_message = "knowledge_base_type must be VECTOR, KENDRA, or SQL."
  }
}

variable "embedding_model_arn" {
  description = "ARN of the Bedrock embedding model. Required when knowledge_base_type = VECTOR."
  type        = string
  default     = null
}

variable "vector_embedding_dimensions" {
  description = "Optional dimensions override for the embedding model."
  type        = number
  default     = null
}

variable "vector_embedding_data_type" {
  description = "Embedding data type: FLOAT32 or BINARY."
  type        = string
  default     = null

  validation {
    condition     = var.vector_embedding_data_type == null || contains(["FLOAT32", "BINARY"], var.vector_embedding_data_type)
    error_message = "vector_embedding_data_type must be FLOAT32 or BINARY when set."
  }
}

variable "supplemental_s3_uri" {
  description = "S3 URI for supplemental multimodal data storage."
  type        = string
  default     = null
}

variable "storage_type" {
  description = "Vector storage backend. One of: OPENSEARCH_SERVERLESS (default), OPENSEARCH_MANAGED_CLUSTER, S3_VECTORS, RDS."
  type        = string
  default     = "OPENSEARCH_SERVERLESS"

  validation {
    condition     = contains(["OPENSEARCH_SERVERLESS", "OPENSEARCH_MANAGED_CLUSTER", "S3_VECTORS", "RDS"], var.storage_type)
    error_message = "storage_type must be OPENSEARCH_SERVERLESS, OPENSEARCH_MANAGED_CLUSTER, S3_VECTORS, or RDS."
  }
}

variable "opensearch_serverless" {
  description = <<-EOT
    OpenSearch Serverless collection settings. Auto-created when storage_type = OPENSEARCH_SERVERLESS.
    All fields are optional — defaults produce a working collection named after var.name.

    collection_name, vector_index_name, description, kms_key_arn,
    public_access, data_access_principals, tags,
    field_metadata / field_text / field_vector  — Bedrock field name overrides
  EOT
  type = object({
    collection_name        = optional(string)
    vector_index_name      = optional(string)
    description            = optional(string)
    kms_key_arn            = optional(string)
    public_access          = optional(bool, true)
    data_access_principals = optional(list(string), [])
    field_metadata         = optional(string, "AMAZON_BEDROCK_METADATA")
    field_text             = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
    field_vector           = optional(string, "bedrock-knowledge-base-default-vector")
    tags                   = optional(map(string), {})
  })
  default = {}
}

variable "opensearch_managed_cluster" {
  description = <<-EOT
    Existing OpenSearch Managed Cluster settings. Used when storage_type = OPENSEARCH_MANAGED_CLUSTER.
    The cluster is NOT auto-created; supply domain_arn, domain_endpoint, and vector_index_name.

    field_metadata / field_text / field_vector  — optional Bedrock field name overrides
  EOT
  type = object({
    domain_arn        = string
    domain_endpoint   = string
    vector_index_name = string
    field_metadata    = optional(string, "AMAZON_BEDROCK_METADATA")
    field_text        = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
    field_vector      = optional(string, "bedrock-knowledge-base-default-vector")
  })
  default = null
}

variable "s3_vectors" {
  description = <<-EOT
    S3 Vectors bucket and index settings. Auto-created when storage_type = S3_VECTORS.

    dimension (required), vector_bucket_name, index_name, data_type, distance_metric, tags
  EOT
  type = object({
    vector_bucket_name = optional(string)
    index_name         = optional(string)
    data_type          = optional(string, "float32")
    dimension          = number
    distance_metric    = optional(string, "euclidean")
    tags               = optional(map(string), {})
  })
  default = null
}

variable "rds" {
  description = <<-EOT
    Aurora PostgreSQL + pgvector settings. Auto-created when storage_type = RDS.

    vpc_id, subnet_ids (required); cluster_identifier, engine_version, database_name,
    master_username, table_name, min_capacity, max_capacity, skip_final_snapshot,
    allowed_cidr_blocks, allowed_security_group_ids, tags,
    field_metadata / field_text / field_vector / field_primary_key  — field name overrides
  EOT
  type = object({
    vpc_id                     = string
    subnet_ids                 = list(string)
    cluster_identifier         = optional(string)
    engine_version             = optional(string, "16.4")
    database_name              = optional(string, "bedrock_kb")
    master_username            = optional(string, "bedrock")
    table_name                 = optional(string, "bedrock_integration.bedrock_kb")
    min_capacity               = optional(number, 0.5)
    max_capacity               = optional(number, 4.0)
    skip_final_snapshot        = optional(bool, true)
    allowed_cidr_blocks        = optional(list(string), [])
    allowed_security_group_ids = optional(list(string), [])
    field_metadata             = optional(string, "metadata")
    field_primary_key          = optional(string, "id")
    field_text                 = optional(string, "chunks")
    field_vector               = optional(string, "embedding")
    tags                       = optional(map(string), {})
  })
  default = null
}

variable "kendra_index_arn" {
  description = "Kendra index ARN. Required when knowledge_base_type = KENDRA."
  type        = string
  default     = null
}

variable "redshift" {
  description = <<-EOT
    Redshift Serverless settings. Auto-created when knowledge_base_type = SQL.

    vpc_id, subnet_ids (required); namespace_name, workgroup_name, database_name,
    admin_username, base_capacity, publicly_accessible,
    allowed_cidr_blocks, allowed_security_group_ids, tags
  EOT
  type = object({
    vpc_id                     = string
    subnet_ids                 = list(string)
    namespace_name             = optional(string)
    workgroup_name             = optional(string)
    database_name              = optional(string, "bedrock_kb")
    admin_username             = optional(string, "admin")
    base_capacity              = optional(number, 8)
    publicly_accessible        = optional(bool, false)
    allowed_cidr_blocks        = optional(list(string), [])
    allowed_security_group_ids = optional(list(string), [])
    tags                       = optional(map(string), {})
  })
  default = null
}
