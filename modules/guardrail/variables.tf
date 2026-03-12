variable "create" {
  description = "Controls whether the guardrail resource is created."
  type        = bool
  default     = true
}

variable "create_version" {
  description = "When true, create a published Bedrock guardrail version."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the Bedrock guardrail."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || length(trimspace(var.name)) > 0
    error_message = "name must not be empty when set."
  }
}

variable "guardrail_arn" {
  description = "Existing guardrail ARN to use when create = false and create_version = true."
  type        = string
  default     = null

  validation {
    condition     = var.guardrail_arn == null || can(regex("^arn:", var.guardrail_arn))
    error_message = "guardrail_arn must be a valid ARN when set."
  }
}

variable "blocked_input_messaging" {
  description = "Message returned when the guardrail blocks an input prompt."
  type        = string
  default     = null
}

variable "blocked_outputs_messaging" {
  description = "Message returned when the guardrail blocks a model output."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description for the guardrail."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the guardrail at rest."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid ARN when set."
  }
}

variable "tags" {
  description = "Tags applied to the guardrail resource."
  type        = map(string)
  default     = {}
}

variable "content_policy_config" {
  description = "Optional content policy configuration."
  type = object({
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
  })
  default = null
}

variable "contextual_grounding_policy_config" {
  description = "Optional contextual grounding policy configuration."
  type = object({
    filters_config = list(object({
      threshold = number
      type      = string
    }))
  })
  default = null
}

variable "cross_region_config" {
  description = "Optional cross-region routing configuration for the guardrail."
  type = object({
    guardrail_profile_identifier = string
  })
  default = null
}

variable "sensitive_information_policy_config" {
  description = "Optional sensitive information policy configuration."
  type = object({
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
  })
  default = null
}

variable "topic_policy_config" {
  description = "Optional topic policy configuration."
  type = object({
    topics_config = list(object({
      definition = string
      examples   = optional(list(string))
      name       = string
      type       = string
    }))
    tier_config = optional(object({
      tier_name = string
    }))
  })
  default = null
}

variable "word_policy_config" {
  description = "Optional word policy configuration."
  type = object({
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
  })
  default = null
}

variable "version_description" {
  description = "Optional description for the published guardrail version."
  type        = string
  default     = null
}

variable "version_skip_destroy" {
  description = "Whether to retain the published guardrail version on destroy."
  type        = bool
  default     = false
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for aws_bedrock_guardrail."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "version_timeouts" {
  description = "Optional create and delete timeouts for aws_bedrock_guardrail_version."
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}
