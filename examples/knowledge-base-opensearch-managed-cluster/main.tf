provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name = "example-os-managed-kb"

  create_knowledge_base = true
  knowledge_base_config = {
    name                       = "example-os-managed-kb"
    role_arn                   = "arn:aws:iam::123456789012:role/bedrock-kb-role"
    type                       = "VECTOR"
    embedding_model_arn        = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    vector_storage_type        = "OPENSEARCH_MANAGED_CLUSTER"
    vector_embedding_data_type = "FLOAT32"

    opensearch_managed_cluster = {
      domain_arn        = "arn:aws:es:us-east-1:123456789012:domain/example-domain"
      domain_endpoint   = "https://search-example-domain.us-east-1.es.amazonaws.com"
      vector_index_name = "example-index"
      field_mapping = {
        metadata_field = "metadata"
        text_field     = "chunks"
        vector_field   = "embedding"
      }
    }
  }
}