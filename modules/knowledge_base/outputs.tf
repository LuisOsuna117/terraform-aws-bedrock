output "id" {
  description = "Knowledge base ID."
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "arn" {
  description = "Knowledge base ARN."
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "name" {
  description = "Knowledge base name."
  value       = aws_bedrockagent_knowledge_base.this.name
}

output "created_at" {
  description = "Timestamp when the knowledge base was created."
  value       = aws_bedrockagent_knowledge_base.this.created_at
}

output "updated_at" {
  description = "Timestamp when the knowledge base was last updated."
  value       = aws_bedrockagent_knowledge_base.this.updated_at
}
