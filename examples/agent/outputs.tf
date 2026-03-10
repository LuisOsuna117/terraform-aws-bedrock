output "agent_id" {
  description = "Bedrock agent ID."
  value       = module.bedrock.agent_id
}

output "agent_arn" {
  description = "Bedrock agent ARN."
  value       = module.bedrock.agent_arn
}

output "agent_aliases" {
  description = "Map of alias key → alias attributes (agent_alias_id, agent_alias_arn)."
  value       = module.bedrock.agent_aliases
}

output "guardrail_id" {
  description = "Guardrail ID auto-wired to the agent."
  value       = module.bedrock.guardrail_id
}
