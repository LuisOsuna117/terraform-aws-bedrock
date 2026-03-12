output "guardrail_id" {
  description = "Guardrail ID."
  value       = try(aws_bedrock_guardrail.this[0].guardrail_id, null)
}

output "guardrail_arn" {
  description = "Guardrail ARN."
  value       = local.resolved_guardrail_arn
}

output "draft_version" {
  description = "Draft version returned by aws_bedrock_guardrail."
  value       = try(aws_bedrock_guardrail.this[0].version, null)
}

output "published_version" {
  description = "Published version returned by aws_bedrock_guardrail_version. Null when create_version = false."
  value       = try(aws_bedrock_guardrail_version.this[0].version, null)
}

output "status" {
  description = "Status of the Bedrock guardrail."
  value       = try(aws_bedrock_guardrail.this[0].status, null)
}

output "created_at" {
  description = "Unix epoch timestamp in seconds for when the guardrail was created."
  value       = try(aws_bedrock_guardrail.this[0].created_at, null)
}
