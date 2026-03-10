variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-guardrail"
}

variable "guardrail_name" {
  description = "Name of the Bedrock guardrail."
  type        = string
  default     = "example-guardrail"
}

variable "blocked_input_messaging" {
  description = "Message returned when the guardrail blocks an input prompt."
  type        = string
  default     = "This request was blocked by the guardrail."
}

variable "blocked_outputs_messaging" {
  description = "Message returned when the guardrail blocks a model output."
  type        = string
  default     = "This response was blocked by the guardrail."
}

variable "guardrail_description" {
  description = "Description for the guardrail example."
  type        = string
  default     = "Example guardrail with content, topic, word, and sensitive information policies."
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "guardrail"
  }
}
