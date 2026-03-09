variable "name" {
  description = "Name of the Bedrock prompt."
  type        = string
}

variable "description" {
  description = "Optional description for the prompt."
  type        = string
  default     = null
}

variable "default_variant" {
  description = "Optional default variant name."
  type        = string
  default     = null
}

variable "customer_encryption_key_arn" {
  description = "Optional KMS key ARN used to encrypt the prompt."
  type        = string
  default     = null
}

variable "region" {
  description = "Optional region override for this resource."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the prompt resource."
  type        = map(string)
  default     = {}
}

variable "variants" {
  description = "List of prompt variants to create."
  type = list(object({
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
  }))
  default = []

  validation {
    condition     = alltrue([for v in var.variants : contains(["TEXT", "CHAT"], v.template_type)])
    error_message = "Each variant.template_type must be either TEXT or CHAT."
  }

  validation {
    condition     = alltrue([for v in var.variants : v.template_type != "TEXT" || try(v.text_template != null && trimspace(v.text_template.text) != "", false)])
    error_message = "Each TEXT variant must include text_template with a non-empty text value."
  }

  validation {
    condition     = alltrue([for v in var.variants : v.template_type != "CHAT" || try(v.chat_template != null, false)])
    error_message = "Each CHAT variant must include chat_template."
  }
}
