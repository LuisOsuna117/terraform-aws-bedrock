provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base   = true
  knowledge_base_name     = var.knowledge_base_name
  knowledge_base_role_arn = var.knowledge_base_role_arn
  knowledge_base_type     = "KENDRA"
  knowledge_base_tags     = var.tags
  kendra_index_arn        = var.kendra_index_arn
}