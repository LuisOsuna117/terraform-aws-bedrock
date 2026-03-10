output "guardrail_id" {
  description = "ID of the created guardrail."
  value       = module.bedrock.guardrail_id
}

output "guardrail_arn" {
  description = "ARN of the created guardrail."
  value       = module.bedrock.guardrail_arn
}

output "guardrail_version" {
  description = "Version of the created guardrail."
  value       = module.bedrock.guardrail_version
}

output "guardrail_status" {
  description = "Status of the created guardrail."
  value       = module.bedrock.guardrail_status
}
