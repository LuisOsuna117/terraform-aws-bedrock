variable "name" {
  description = "Base name used as a prefix for resources when per-module names are not explicitly set."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,63}$", var.name))
    error_message = "name must start with a letter, be at most 64 characters, and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Tags merged onto all resources managed by this module."
  type        = map(string)
  default     = {}
}

variable "create_knowledge_base" {
  description = "When true, creates a Bedrock knowledge base using modules/knowledge_base."
  type        = bool
  default     = false
}

variable "knowledge_base_name" {
  description = "Explicit name for the knowledge base. Defaults to var.name when not set."
  type        = string
  default     = null
}

variable "knowledge_base_description" {
  description = "Optional description for the knowledge base."
  type        = string
  default     = null
}

variable "knowledge_base_role_arn" {
  description = "IAM role ARN used by the knowledge base. Required when create_knowledge_base = true."
  type        = string
  default     = null
}

variable "knowledge_base_region" {
  description = "Optional region override for the knowledge base resource."
  type        = string
  default     = null
}

variable "knowledge_base_tags" {
  description = "Additional tags applied specifically to knowledge base resources."
  type        = map(string)
  default     = {}
}

variable "knowledge_base_type" {
  description = "Knowledge base type: VECTOR (default), KENDRA, or SQL."
  type        = string
  default     = "VECTOR"
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
}

variable "supplemental_s3_uri" {
  description = "S3 URI for supplemental multimodal data storage."
  type        = string
  default     = null
}

variable "storage_type" {
  description = "Vector storage backend: S3_VECTORS (default), OPENSEARCH_SERVERLESS, OPENSEARCH_MANAGED_CLUSTER, or RDS."
  type        = string
  default     = "S3_VECTORS"
}

variable "opensearch_serverless" {
  description = "OpenSearch Serverless collection settings. Auto-created when storage_type = OPENSEARCH_SERVERLESS."
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
  description = "Existing OpenSearch Managed Cluster settings. Used when storage_type = OPENSEARCH_MANAGED_CLUSTER."
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
  description = "S3 Vectors bucket and index settings. Auto-created when storage_type = S3_VECTORS."
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
  description = "Aurora PostgreSQL + pgvector settings. Auto-created when storage_type = RDS."
  type = object({
    vpc_id                          = string
    subnet_ids                      = list(string)
    cluster_identifier              = optional(string)
    engine_version                  = optional(string, "16.4")
    database_name                   = optional(string, "bedrock_kb")
    master_username                 = optional(string, "bedrock")
    table_name                      = optional(string, "bedrock_integration.bedrock_kb")
    min_capacity                    = optional(number, 0.5)
    max_capacity                    = optional(number, 4.0)
    skip_final_snapshot             = optional(bool, true)
    allowed_cidr_blocks             = optional(list(string), [])
    allowed_security_group_ids      = optional(list(string), [])
    allowed_egress_cidr_blocks      = optional(list(string), [])
    kms_key_id                      = optional(string)
    backup_retention_period         = optional(number, 7)
    deletion_protection             = optional(bool, true)
    performance_insights_enabled    = optional(bool, true)
    performance_insights_kms_key_id = optional(string)
    field_metadata                  = optional(string, "metadata")
    field_primary_key               = optional(string, "id")
    field_text                      = optional(string, "chunks")
    field_vector                    = optional(string, "embedding")
    tags                            = optional(map(string), {})
  })
  default = null
}

variable "kendra_index_arn" {
  description = "Kendra index ARN. Required when knowledge_base_type = KENDRA."
  type        = string
  default     = null
}

variable "redshift" {
  description = "Redshift Serverless settings. Auto-created when knowledge_base_type = SQL."
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
    allowed_egress_cidr_blocks = optional(list(string), [])
    tags                       = optional(map(string), {})
  })
  default = null
}

variable "create_prompt_management" {
  description = "When true, creates a Bedrock prompt resource using modules/prompt_management."
  type        = bool
  default     = false
}

variable "prompt_management_config" {
  description = "Configuration object for the prompt management module. Required when create_prompt_management = true."
  type = object({
    tags = optional(map(string), {})
    prompts = optional(map(object({
      name                        = string
      description                 = optional(string)
      default_variant             = optional(string)
      customer_encryption_key_arn = optional(string)
      region                      = optional(string)
      tags                        = optional(map(string), {})
      variants = optional(list(object({
        name                            = string
        template_type                   = string
        model_id                        = optional(string)
        additional_model_request_fields = optional(map(any))
        metadata                        = optional(map(string))
        gen_ai_agent_identifier         = optional(string)
        inference_text = optional(object({
          max_tokens     = optional(number)
          stop_sequences = optional(list(string))
          temperature    = optional(number)
          top_p          = optional(number)
        }))
        text_template = optional(object({
          text             = string
          input_variables  = optional(list(string), [])
          cache_point_type = optional(string)
        }))
        chat_template = optional(object({
          input_variables = optional(list(string), [])
          messages = optional(list(object({
            role             = string
            text             = optional(string)
            cache_point_type = optional(string)
          })), [])
          system_prompts = optional(list(object({
            text             = optional(string)
            cache_point_type = optional(string)
          })), [])
        }))
      })), [])
    })), {})
  })
  default = null
}

variable "create_guardrail" {
  description = "When true, creates an Amazon Bedrock guardrail using modules/guardrail."
  type        = bool
  default     = false
}

variable "create_agent" {
  description = "When true, creates a Bedrock agent and its child resources using modules/agent."
  type        = bool
  default     = false
}

variable "guardrail_config" {
  description = "Configuration object for the guardrail module. Required when create_guardrail = true."
  type = object({
    name                      = optional(string)
    blocked_input_messaging   = string
    blocked_outputs_messaging = string
    description               = optional(string)
    kms_key_arn               = optional(string)
    region                    = optional(string)
    tags                      = optional(map(string), {})
    content_policy_config = optional(object({
      filters_config = optional(list(object({
        input_action      = optional(string)
        input_enabled     = optional(bool)
        input_modalities  = optional(list(string))
        input_strength    = optional(string)
        output_action     = optional(string)
        output_enabled    = optional(bool)
        output_modalities = optional(list(string))
        output_strength   = optional(string)
        type              = optional(string)
      })), [])
      tier_config = optional(object({
        tier_name = string
      }))
    }))
    contextual_grounding_policy_config = optional(object({
      filters_config = list(object({
        threshold = number
        type      = string
      }))
    }))
    cross_region_config = optional(object({
      guardrail_profile_identifier = string
    }))
    sensitive_information_policy_config = optional(object({
      pii_entities_config = optional(list(object({
        action         = string
        input_action   = optional(string)
        input_enabled  = optional(bool)
        output_action  = optional(string)
        output_enabled = optional(bool)
        type           = string
      })), [])
      regexes_config = optional(list(object({
        action         = string
        description    = optional(string)
        input_action   = optional(string)
        input_enabled  = optional(bool)
        name           = string
        output_action  = optional(string)
        output_enabled = optional(bool)
        pattern        = string
      })), [])
    }))
    topic_policy_config = optional(object({
      topics_config = list(object({
        definition = string
        examples   = optional(list(string))
        name       = string
        type       = string
      }))
      tier_config = optional(object({
        tier_name = string
      }))
    }))
    word_policy_config = optional(object({
      managed_word_lists_config = optional(list(object({
        input_action   = optional(string)
        input_enabled  = optional(bool)
        output_action  = optional(string)
        output_enabled = optional(bool)
        type           = string
      })), [])
      words_config = optional(list(object({
        input_action   = optional(string)
        input_enabled  = optional(bool)
        output_action  = optional(string)
        output_enabled = optional(bool)
        text           = string
      })), [])
    }))
  })
  default = null
}

variable "agent_config" {
  description = "Configuration object for the agent module. Required when create_agent = true."
  type = object({
    name                        = optional(string)
    role_arn                    = string
    foundation_model            = string
    instruction                 = optional(string)
    description                 = optional(string)
    idle_session_ttl_in_seconds = optional(number, 600)
    agent_collaboration         = optional(string, "DISABLED")
    customer_encryption_key_arn = optional(string)
    prepare_agent               = optional(bool, true)
    skip_resource_in_use_check  = optional(bool, false)
    region                      = optional(string)
    tags                        = optional(map(string), {})
    guardrail_id                = optional(string)
    guardrail_version           = optional(string, "DRAFT")

    memory_configuration = optional(object({
      enabled_memory_types = list(string)
      storage_days         = optional(number)
      max_recent_sessions  = optional(number)
    }))

    action_groups = optional(map(object({
      name                          = optional(string)
      description                   = optional(string)
      action_group_state            = optional(string, "ENABLED")
      parent_action_group_signature = optional(string)
      lambda_arn                    = optional(string)
      custom_control                = optional(string)
      api_schema_payload            = optional(string)
      api_schema_s3_bucket          = optional(string)
      api_schema_s3_key             = optional(string)
      prepare_agent                 = optional(bool, true)
      skip_resource_in_use_check    = optional(bool, true)
      region                        = optional(string)
      function_schema = optional(object({
        functions = optional(list(object({
          name        = string
          description = optional(string)
          parameters = optional(list(object({
            name        = string
            type        = string
            description = optional(string)
            required    = optional(bool)
          })), [])
        })), [])
      }))
    })), {})

    knowledge_base_associations = optional(map(object({
      knowledge_base_id    = string
      description          = string
      knowledge_base_state = optional(string, "ENABLED")
      region               = optional(string)
    })), {})

    aliases = optional(map(object({
      name                   = optional(string)
      description            = optional(string)
      agent_version          = optional(string)
      provisioned_throughput = optional(string)
      region                 = optional(string)
      tags                   = optional(map(string), {})
    })), {})

    collaborators = optional(map(object({
      name                       = optional(string)
      alias_arn                  = string
      collaboration_instruction  = string
      relay_conversation_history = optional(string)
      prepare_agent              = optional(bool, true)
      region                     = optional(string)
    })), {})
  })
  default = null
}