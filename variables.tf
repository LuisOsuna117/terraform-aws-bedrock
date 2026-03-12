variable "create" {
  description = "Top-level module enable flag."
  type        = bool
  default     = true
}

variable "name" {
  description = "Base name used by child modules when a feature-specific name override is not set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags merged onto all managed resources. Feature-specific tag maps are merged on top."
  type        = map(string)
  default     = {}
}

variable "create_knowledge_base" {
  description = "When true, create the Bedrock knowledge base submodule."
  type        = bool
  default     = false
}

variable "create_guardrail" {
  description = "When true, create the Bedrock guardrail submodule."
  type        = bool
  default     = false
}

variable "knowledge_base" {
  description = "Knowledge base configuration forwarded to modules/knowledge_base."
  type = object({
    name                             = optional(string)
    description                      = optional(string)
    create_role                      = optional(bool, true)
    create_vector_bucket             = optional(bool, true)
    create_vector_index              = optional(bool, true)
    role_arn                         = optional(string)
    embedding_model_arn              = optional(string)
    supplemental_data_storage_s3_uri = optional(string)
    iam_role = optional(object({
      name                 = optional(string)
      description          = optional(string)
      path                 = optional(string, "/")
      permissions_boundary = optional(string)
      max_session_duration = optional(number, 3600)
      tags                 = optional(map(string), {})
    }), {})
    iam_role_additional_policy_documents = optional(list(string), [])
    s3_vectors = optional(object({
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
    }), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  })
  default = {}
}

variable "guardrail" {
  description = "Guardrail configuration forwarded to modules/guardrail."
  type = object({
    name                      = optional(string)
    create_version            = optional(bool, false)
    blocked_input_messaging   = optional(string)
    blocked_outputs_messaging = optional(string)
    description               = optional(string)
    kms_key_arn               = optional(string)
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
    version_description  = optional(string)
    version_skip_destroy = optional(bool, false)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    version_timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  })
  default = {}
}
