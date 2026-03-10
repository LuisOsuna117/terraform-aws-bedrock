output "prompts" {
  description = "Map of logical key → prompt attributes (id, arn, name, version, created_at, updated_at)."
  value = {
    for k, p in aws_bedrockagent_prompt.this : k => {
      id         = p.id
      arn        = p.arn
      name       = p.name
      version    = p.version
      created_at = p.created_at
      updated_at = p.updated_at
    }
  }
}
