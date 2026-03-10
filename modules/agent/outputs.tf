output "agent_id" {
  description = "Unique identifier of the agent."
  value       = aws_bedrockagent_agent.this.agent_id
}

output "agent_arn" {
  description = "ARN of the agent."
  value       = aws_bedrockagent_agent.this.agent_arn
}

output "agent_name" {
  description = "Name of the agent."
  value       = aws_bedrockagent_agent.this.agent_name
}

output "agent_version" {
  description = "Current agent version (DRAFT until a version is created)."
  value       = aws_bedrockagent_agent.this.agent_version
}

output "aliases" {
  description = "Map of logical key → alias attributes (agent_alias_id, agent_alias_arn)."
  value = {
    for k, a in aws_bedrockagent_agent_alias.this : k => {
      agent_alias_id  = a.agent_alias_id
      agent_alias_arn = a.agent_alias_arn
    }
  }
}

output "action_group_ids" {
  description = "Map of logical key → action group ID."
  value       = { for k, ag in aws_bedrockagent_agent_action_group.this : k => ag.action_group_id }
}

output "collaborator_ids" {
  description = "Map of logical key → collaborator ID."
  value       = { for k, c in aws_bedrockagent_agent_collaborator.this : k => c.collaborator_id }
}
