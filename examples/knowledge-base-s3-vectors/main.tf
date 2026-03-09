provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name = "example-s3-vectors-kb"

  create_knowledge_base = true
  knowledge_base_config = {
    name                        = "example-s3-vectors-kb"
    role_arn                    = "arn:aws:iam::123456789012:role/bedrock-kb-role"
    type                        = "VECTOR"
    embedding_model_arn         = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    vector_embedding_dimensions = 256
    vector_embedding_data_type  = "FLOAT32"
    vector_storage_type         = "S3_VECTORS"

    s3_vectors = {
      index_arn = "arn:aws:s3vectors:us-east-1:123456789012:bucket/example-vector-bucket/index/example-index"
    }
  }
}