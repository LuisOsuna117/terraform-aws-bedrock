output "prompts" {
  description = "Map of logical key → prompt attributes (id, arn, name, version)."
  value       = module.bedrock.prompts
}

output "prompt_bridge_environment_variables" {
  description = "Environment variable map produced by the prompt bridge."
  value       = module.bedrock.prompt_bridge_environment_variables
}
