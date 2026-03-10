locals {
  is_vector = var.knowledge_base_type == "VECTOR"
  is_kendra = var.knowledge_base_type == "KENDRA"
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !local.is_vector || var.vector_config != null
      error_message = "vector_config must be provided when knowledge_base_type = VECTOR."
    }

    precondition {
      condition     = !local.is_kendra || var.kendra_config != null
      error_message = "kendra_config must be provided when knowledge_base_type = KENDRA."
    }

    precondition {
      condition     = !local.is_vector || try(trimspace(var.vector_config.embedding_model_arn) != "", false)
      error_message = "vector_config.embedding_model_arn must be set when knowledge_base_type = VECTOR."
    }

    precondition {
      condition     = !local.is_kendra || try(trimspace(var.kendra_config.kendra_index_arn) != "", false)
      error_message = "kendra_config.kendra_index_arn must be set when knowledge_base_type = KENDRA."
    }
  }
}

resource "aws_bedrockagent_knowledge_base" "this" {
  name        = var.name
  description = var.description
  role_arn    = var.role_arn
  region      = var.region
  tags        = var.tags

  knowledge_base_configuration {
    type = var.knowledge_base_type

    dynamic "vector_knowledge_base_configuration" {
      for_each = local.is_vector ? [1] : []
      content {
        embedding_model_arn = var.vector_config.embedding_model_arn

        dynamic "embedding_model_configuration" {
          for_each = var.vector_config.vector_embedding_dimensions != null || var.vector_config.vector_embedding_data_type != null ? [1] : []
          content {
            bedrock_embedding_model_configuration {
              dimensions          = var.vector_config.vector_embedding_dimensions
              embedding_data_type = var.vector_config.vector_embedding_data_type
            }
          }
        }

        dynamic "supplemental_data_storage_configuration" {
          for_each = try(var.vector_config.supplemental_s3_uri, null) != null ? [1] : []
          content {
            storage_location {
              type = "S3"
              s3_location {
                uri = var.vector_config.supplemental_s3_uri
              }
            }
          }
        }
      }
    }

    dynamic "kendra_knowledge_base_configuration" {
      for_each = local.is_kendra ? [1] : []
      content {
        kendra_index_arn = var.kendra_config.kendra_index_arn
      }
    }
  }

  dynamic "storage_configuration" {
    for_each = local.is_vector ? [1] : []
    content {
      type = var.vector_config.storage_type

      dynamic "opensearch_serverless_configuration" {
        for_each = var.vector_config.storage_type == "OPENSEARCH_SERVERLESS" ? [1] : []
        content {
          collection_arn    = var.vector_config.opensearch_serverless.collection_arn
          vector_index_name = var.vector_config.opensearch_serverless.vector_index_name

          field_mapping {
            metadata_field = var.vector_config.opensearch_serverless.field_mapping.metadata_field
            text_field     = var.vector_config.opensearch_serverless.field_mapping.text_field
            vector_field   = var.vector_config.opensearch_serverless.field_mapping.vector_field
          }
        }
      }

      dynamic "opensearch_managed_cluster_configuration" {
        for_each = var.vector_config.storage_type == "OPENSEARCH_MANAGED_CLUSTER" ? [1] : []
        content {
          domain_arn        = var.vector_config.opensearch_managed_cluster.domain_arn
          domain_endpoint   = var.vector_config.opensearch_managed_cluster.domain_endpoint
          vector_index_name = var.vector_config.opensearch_managed_cluster.vector_index_name

          field_mapping {
            metadata_field = var.vector_config.opensearch_managed_cluster.field_mapping.metadata_field
            text_field     = var.vector_config.opensearch_managed_cluster.field_mapping.text_field
            vector_field   = var.vector_config.opensearch_managed_cluster.field_mapping.vector_field
          }
        }
      }

      dynamic "s3_vectors_configuration" {
        for_each = var.vector_config.storage_type == "S3_VECTORS" ? [1] : []
        content {
          index_arn         = var.vector_config.s3_vectors.index_arn
          index_name        = var.vector_config.s3_vectors.index_name
          vector_bucket_arn = var.vector_config.s3_vectors.vector_bucket_arn
        }
      }
    }
  }

  depends_on = [terraform_data.validations]
}
