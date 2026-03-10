variable "name" {
  description = "Agent name."
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role the agent uses to invoke the foundation model and other AWS services."
  type        = string
}

variable "foundation_model" {
  description = "Foundation model ID (e.g. anthropic.claude-3-5-sonnet-20241022-v2:0)."
  type        = string
}

variable "instruction" {
  description = "Instructions that describe what the agent does (40–20 000 chars). Required when prepare_agent = true."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description of the agent."
  type        = string
  default     = null
}

variable "idle_session_ttl_in_seconds" {
  description = "Inactivity timeout in seconds before the session expires (0–3600)."
  type        = number
  default     = 600
}

variable "agent_collaboration" {
  description = "Collaboration role for this agent. Valid values: SUPERVISOR, SUPERVISOR_ROUTER, DISABLED."
  type        = string
  default     = "DISABLED"
}

variable "customer_encryption_key_arn" {
  description = "KMS key ARN used to encrypt the agent."
  type        = string
  default     = null
}

variable "prepare_agent" {
  description = "Whether to prepare the agent after creation or modification."
  type        = bool
  default     = true
}

variable "skip_resource_in_use_check" {
  description = "Whether to skip the in-use check when deleting the agent."
  type        = bool
  default     = false
}

variable "region" {
  description = "Optional region override for the agent resource."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Guardrail integration (pass outputs from modules/guardrail)
# ---------------------------------------------------------------------------
variable "guardrail_id" {
  description = "Guardrail identifier to associate with this agent. Accepts the guardrail_id output from modules/guardrail."
  type        = string
  default     = null
}

variable "guardrail_version" {
  description = "Guardrail version to attach. Defaults to DRAFT."
  type        = string
  default     = "DRAFT"
}

# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------
variable "memory_configuration" {
  description = "Optional memory configuration for the agent."
  type = object({
    enabled_memory_types = list(string)
    storage_days         = optional(number)
    max_recent_sessions  = optional(number)
  })
  default = null
}

# ---------------------------------------------------------------------------
# Action groups
# ---------------------------------------------------------------------------
variable "action_groups" {
  description = <<-EOT
    Map of logical key → action group configuration.

    Schema per entry:
      name                          - override the action group name (default: map key)
      description                   - optional description
      action_group_state            - ENABLED (default) or DISABLED
      parent_action_group_signature - "AMAZON.UserInput" to enable the built-in user-input
                                      action; omit executor/api_schema/description for this type.
      lambda_arn                    - ARN of the Lambda function to execute
      custom_control                - "RETURN_CONTROL" to return control to the caller
      api_schema_payload            - inline OpenAPI schema string (JSON or YAML)
      api_schema_s3_bucket          - S3 bucket containing the schema
      api_schema_s3_key             - S3 object key for the schema
      function_schema.functions     - list of simplified function definitions (name, description, parameters)
      prepare_agent                 - re-prepare the agent after group creation (default: true)
      skip_resource_in_use_check    - skip the in-use check on delete (default: true)
  EOT
  type = map(object({
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
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Knowledge base associations
# ---------------------------------------------------------------------------
variable "knowledge_base_associations" {
  description = <<-EOT
    Map of logical key → knowledge base association.
    knowledge_base_id is typically the knowledge_base_id output from modules/knowledge_base.
  EOT
  type = map(object({
    knowledge_base_id    = string
    description          = string
    knowledge_base_state = optional(string, "ENABLED")
    region               = optional(string)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
variable "aliases" {
  description = <<-EOT
    Map of logical key → alias configuration.
    Omit agent_version to create a floating DRAFT alias.
    Set agent_version to a specific version number to pin the alias.
  EOT
  type = map(object({
    name                   = optional(string)
    description            = optional(string)
    agent_version          = optional(string)
    provisioned_throughput = optional(string)
    region                 = optional(string)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Collaborators (supervisor/supervisor-router pattern)
# ---------------------------------------------------------------------------
variable "collaborators" {
  description = <<-EOT
    Map of logical key → sub-agent collaborator.
    Requires agent_collaboration = SUPERVISOR or SUPERVISOR_ROUTER on this agent.
    alias_arn is the agent_alias_arn of the sub-agent.
  EOT
  type = map(object({
    name                       = optional(string)
    alias_arn                  = string
    collaboration_instruction  = string
    relay_conversation_history = optional(string)
    prepare_agent              = optional(bool, true)
    region                     = optional(string)
  }))
  default = {}
}
