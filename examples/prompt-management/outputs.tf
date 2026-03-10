output "prompt_id" {
  description = "ID of the managed prompt."
  value       = module.bedrock.prompt_id
}

output "prompt_arn" {
  description = "ARN of the managed prompt."
  value       = module.bedrock.prompt_arn
}

output "prompt_version" {
  description = "Version of the managed prompt."
  value       = module.bedrock.prompt_version
}

output "prompt_bridge_environment_variables" {
  description = "Environment variable map produced by the prompt bridge."
  value       = module.bedrock.prompt_bridge_environment_variables
}
