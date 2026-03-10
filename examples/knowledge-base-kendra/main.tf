provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base = true
  knowledge_base_config = {
    name             = var.knowledge_base_name
    role_arn         = var.knowledge_base_role_arn
    type             = "KENDRA"
    kendra_index_arn = var.kendra_index_arn
    tags             = var.tags
  }
}