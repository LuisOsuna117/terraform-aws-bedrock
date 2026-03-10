provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base   = true
  knowledge_base_name     = var.knowledge_base_name
  knowledge_base_role_arn = var.knowledge_base_role_arn
  knowledge_base_tags     = var.tags
  embedding_model_arn     = var.embedding_model_arn
  storage_type            = "OPENSEARCH_SERVERLESS"

  opensearch_serverless = {
    vector_index_name = var.vector_index_name
    field_metadata    = var.metadata_field
    field_text        = var.text_field
    field_vector      = var.vector_field
  }
}