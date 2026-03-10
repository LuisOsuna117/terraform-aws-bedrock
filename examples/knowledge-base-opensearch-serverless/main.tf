provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base = true
  knowledge_base_config = {
    name                = var.knowledge_base_name
    role_arn            = var.knowledge_base_role_arn
    type                = "VECTOR"
    embedding_model_arn = var.embedding_model_arn
    vector_storage_type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless = {
      collection_arn    = var.collection_arn
      vector_index_name = var.vector_index_name
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
        vector_field   = var.vector_field
      }
    }

    tags = var.tags
  }
}