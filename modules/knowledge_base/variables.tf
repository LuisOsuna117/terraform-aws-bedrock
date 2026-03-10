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

variable "vector_config" {
  description = <<-EOT
    Configuration for VECTOR knowledge bases. Required when knowledge_base_type = VECTOR.

    embedding_model_arn         - ARN of the Bedrock embedding model (required)
    vector_embedding_dimensions - Optional dimensions override
    vector_embedding_data_type  - FLOAT32 or BINARY
    supplemental_s3_uri         - S3 URI for supplemental multimodal data
    storage_type                - OPENSEARCH_SERVERLESS | OPENSEARCH_MANAGED_CLUSTER | S3_VECTORS

    s3_vectors (auto-created):
      vector_bucket_name - bucket name (default: var.name)
      index_name         - index name  (default: var.name)
      data_type          - float32 or binary (default: float32)
      dimension          - vector dimension, required
      distance_metric    - euclidean | cosine | dot_product (default: euclidean)
      tags               - additional tags for the bucket

    opensearch_serverless (auto-created — collection + encryption/network/data-access policies):
      collection_name        - collection name (default: var.name, max 32 chars)
      vector_index_name      - index name to reference in the KB (default: var.name)
      description            - optional collection description
      kms_key_arn            - customer KMS key to encrypt the collection; null = AWS-owned key
      public_access          - allow public network access (default: true)
      data_access_principals - extra IAM principal ARNs granted index read/write access
      field_mapping          - override Bedrock default field names in the index
      tags                   - additional tags for the collection

    opensearch_managed_cluster (existing cluster, not auto-created):
      domain_arn, domain_endpoint, vector_index_name, field_mapping
  EOT
  type = object({
    embedding_model_arn         = string
    vector_embedding_dimensions = optional(number)
    vector_embedding_data_type  = optional(string)
    supplemental_s3_uri         = optional(string)
    storage_type                = string

    # Auto-created when storage_type = S3_VECTORS
    s3_vectors = optional(object({
      vector_bucket_name = optional(string)
      index_name         = optional(string)
      data_type          = optional(string, "float32")
      dimension          = number
      distance_metric    = optional(string, "euclidean")
      tags               = optional(map(string), {})
    }))

    # Auto-created when storage_type = RDS (Aurora PostgreSQL + pgvector)
    rds = optional(object({
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
      field_mapping = optional(object({
        metadata_field    = optional(string, "metadata")
        primary_key_field = optional(string, "id")
        text_field        = optional(string, "chunks")
        vector_field      = optional(string, "embedding")
      }), {})
      tags = optional(map(string), {})
    }))

    # Auto-created when storage_type = OPENSEARCH_SERVERLESS
    opensearch_serverless = optional(object({
      collection_name        = optional(string)
      vector_index_name      = optional(string)
      description            = optional(string)
      kms_key_arn            = optional(string)
      public_access          = optional(bool, true)
      data_access_principals = optional(list(string), [])
      field_mapping = optional(object({
        metadata_field = optional(string, "AMAZON_BEDROCK_METADATA")
        text_field     = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
        vector_field   = optional(string, "bedrock-knowledge-base-default-vector")
      }), {})
      tags = optional(map(string), {})
    }))

    # Existing cluster — not auto-created; provide all details explicitly
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

variable "redshift_config" {
  description = <<-EOT
    Configuration for SQL (Redshift Serverless) knowledge bases. Required when knowledge_base_type = SQL.

    vpc_id                     - VPC where the Redshift workgroup is deployed (required)
    subnet_ids                 - Subnets for the workgroup (required, ≥3 across AZs recommended)
    namespace_name             - Namespace name (defaults to var.name)
    workgroup_name             - Workgroup name (defaults to var.name)
    database_name              - Database to create and query (default: bedrock_kb)
    admin_username             - Admin user (default: admin); password managed by AWS Secrets Manager
    base_capacity              - Redshift Processing Units for the workgroup (default: 8)
    publicly_accessible        - Whether the workgroup endpoint is publicly accessible (default: false)
    allowed_cidr_blocks        - Ingress CIDR blocks for port 5439 (default: none)
    allowed_security_group_ids - Ingress security groups for port 5439 (default: none)
    tags                       - Additional tags
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
