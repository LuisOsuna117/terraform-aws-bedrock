output "id" {
  description = "Prompt ID."
  value       = aws_bedrockagent_prompt.this.id
}

output "arn" {
  description = "Prompt ARN."
  value       = aws_bedrockagent_prompt.this.arn
}

output "name" {
  description = "Prompt name."
  value       = aws_bedrockagent_prompt.this.name
}

output "version" {
  description = "Prompt version (DRAFT on create)."
  value       = aws_bedrockagent_prompt.this.version
}

output "created_at" {
  description = "Timestamp when the prompt was created."
  value       = aws_bedrockagent_prompt.this.created_at
}

output "updated_at" {
  description = "Timestamp when the prompt was last updated."
  value       = aws_bedrockagent_prompt.this.updated_at
}
