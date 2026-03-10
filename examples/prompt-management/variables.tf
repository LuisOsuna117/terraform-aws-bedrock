variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "module_name" {
  description = "Base name passed to the root module."
  type        = string
  default     = "example-prompt-management"
}

variable "prompt_name" {
  description = "Name of the managed prompt."
  type        = string
  default     = "example-system-prompt"
}

variable "prompt_description" {
  description = "Description for the managed prompt."
  type        = string
  default     = "Prompt management example with multiple variants."
}

variable "default_variant" {
  description = "Default text variant name."
  type        = string
  default     = "default"
}

variable "chat_variant_name" {
  description = "Chat variant name."
  type        = string
  default     = "chat-default"
}

variable "model_id" {
  description = "Foundation model ID used by prompt variants."
  type        = string
  default     = "amazon.titan-text-express-v1"
}

variable "tags" {
  description = "Tags applied to resources created by this example."
  type        = map(string)
  default = {
    Example = "prompt-management"
  }
}
