variable "tags" {
  description = "Tags merged onto every prompt resource created by this module."
  type        = map(string)
  default     = {}
}

variable "prompts" {
  description = "Map of logical key → prompt configuration. Creates one aws_bedrockagent_prompt per entry."
  type = map(object({
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
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for k, p in var.prompts : [
        for v in try(p.variants, []) : contains(["TEXT", "CHAT"], v.template_type)
      ]
    ]))
    error_message = "Each variant.template_type must be TEXT or CHAT."
  }

  validation {
    condition = alltrue(flatten([
      for k, p in var.prompts : [
        for v in try(p.variants, []) :
        v.template_type != "TEXT" || try(v.text_template != null && trimspace(v.text_template.text) != "", false)
      ]
    ]))
    error_message = "Each TEXT variant must include text_template with a non-empty text value."
  }

  validation {
    condition = alltrue(flatten([
      for k, p in var.prompts : [
        for v in try(p.variants, []) :
        v.template_type != "CHAT" || try(v.chat_template != null, false)
      ]
    ]))
    error_message = "Each CHAT variant must include chat_template."
  }
}
