provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base       = true
  knowledge_base_name         = var.knowledge_base_name
  knowledge_base_role_arn     = var.knowledge_base_role_arn
  knowledge_base_tags         = var.tags
  embedding_model_arn         = var.embedding_model_arn
  vector_embedding_dimensions = var.vector_embedding_dimensions
  vector_embedding_data_type  = var.vector_embedding_data_type
  storage_type                = "S3_VECTORS"

  s3_vectors = {
    dimension = var.vector_embedding_dimensions
  }
}