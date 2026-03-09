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

variable "knowledge_base_config" {
  description = "Configuration object for the knowledge base module. Required when create_knowledge_base = true."
  type = object({
    name                        = optional(string)
    description                 = optional(string)
    role_arn                    = string
    region                      = optional(string)
    tags                        = optional(map(string), {})
    type                        = optional(string, "VECTOR")
    embedding_model_arn         = optional(string)
    vector_embedding_dimensions = optional(number)
    vector_embedding_data_type  = optional(string)
    supplemental_s3_uri         = optional(string)
    kendra_index_arn            = optional(string)
    vector_storage_type         = optional(string)

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
}

variable "create_prompt_management" {
  description = "When true, creates a Bedrock prompt resource using modules/prompt_management."
  type        = bool
  default     = false
}

variable "prompt_management_config" {
  description = "Configuration object for the prompt management module. Required when create_prompt_management = true."
  type = object({
    name                        = optional(string)
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
  })
  default = null
}

variable "create_prompt_bridge" {
  description = "When true, exposes resolved prompt references and environment variables for AgentCore/app runtimes. No IAM resources are created."
  type        = bool
  default     = false
}

variable "prompt_bridge_config" {
  description = "Bridge configuration for reusing Bedrock Prompt Management from external runtimes (such as AgentCore apps)."
  type = object({
    existing_prompt_arn = optional(string)
    existing_prompt_id  = optional(string)
    prompt_version      = optional(string)
    env_var_names = optional(object({
      prompt_id      = optional(string, "BEDROCK_PROMPT_ID")
      prompt_arn     = optional(string, "BEDROCK_PROMPT_ARN")
      prompt_version = optional(string, "BEDROCK_PROMPT_VERSION")
    }), {})
  })
  default = null
}