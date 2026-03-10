output "prompts" {
  description = "Map of logical key → prompt attributes (id, arn, name, version)."
  value       = module.bedrock.prompts
}

