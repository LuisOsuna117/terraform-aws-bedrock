output "guardrail_id" {
  description = "Guardrail ID."
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "Guardrail ARN."
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "version" {
  description = "Guardrail version."
  value       = aws_bedrock_guardrail.this.version
}

output "status" {
  description = "Guardrail status."
  value       = aws_bedrock_guardrail.this.status
}

output "created_at" {
  description = "Unix epoch timestamp in seconds for when the guardrail was created."
  value       = aws_bedrock_guardrail.this.created_at
}
