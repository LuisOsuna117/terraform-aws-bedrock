provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name = "example-kendra-kb"

  create_knowledge_base = true
  knowledge_base_config = {
    name             = "example-kendra-kb"
    role_arn         = "arn:aws:iam::123456789012:role/bedrock-kb-role"
    type             = "KENDRA"
    kendra_index_arn = "arn:aws:kendra:us-east-1:123456789012:index/example-index-id"
  }
}