provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name = "example-os-serverless-kb"

  create_knowledge_base = true
  knowledge_base_config = {
    name                = "example-os-serverless-kb"
    role_arn            = "arn:aws:iam::123456789012:role/bedrock-kb-role"
    type                = "VECTOR"
    embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    vector_storage_type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless = {
      collection_arn    = "arn:aws:aoss:us-east-1:123456789012:collection/examplecollection"
      vector_index_name = "bedrock-kb-index"
      field_mapping = {
        metadata_field = "AMAZON_BEDROCK_METADATA"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        vector_field   = "bedrock-knowledge-base-default-vector"
      }
    }
  }
}