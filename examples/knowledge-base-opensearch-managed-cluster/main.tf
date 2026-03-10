provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base = true
  knowledge_base_config = {
    name                       = var.knowledge_base_name
    role_arn                   = var.knowledge_base_role_arn
    type                       = "VECTOR"
    embedding_model_arn        = var.embedding_model_arn
    vector_storage_type        = "OPENSEARCH_MANAGED_CLUSTER"
    vector_embedding_data_type = var.vector_embedding_data_type

    opensearch_managed_cluster = {
      domain_arn        = var.domain_arn
      domain_endpoint   = var.domain_endpoint
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