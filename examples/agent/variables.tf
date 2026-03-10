variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module (used as agent name and guardrail name)."
  type        = string
  default     = "example-agent"
}

variable "agent_role_arn" {
  description = "ARN of the IAM role the Bedrock agent assumes to invoke foundation models and other AWS services."
  type        = string
}

variable "foundation_model" {
  description = "Foundation model ID used by the agent (e.g. anthropic.claude-3-5-sonnet-20241022-v2:0)."
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20241022-v2:0"
}

variable "knowledge_base_id" {
  description = "Optional knowledge base ID to associate with the agent. Leave empty to skip the association."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "agent"
  }
}
