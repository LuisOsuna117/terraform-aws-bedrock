output "guardrail_arn" {
  description = "ARN of the managed Bedrock guardrail."
  value       = module.bedrock.guardrail_arn
}

output "guardrail_status" {
  description = "Status of the managed Bedrock guardrail."
  value       = module.bedrock.guardrail_status
}

output "guardrail_published_version" {
  description = "Published version created by the guardrail module."
  value       = module.bedrock.guardrail_published_version
}
