locals {
  is_vector                = var.knowledge_base_type == "VECTOR"
  is_kendra                = var.knowledge_base_type == "KENDRA"
  is_s3_vectors            = local.is_vector && try(var.vector_config.storage_type, "") == "S3_VECTORS"
  is_opensearch_serverless = local.is_vector && try(var.vector_config.storage_type, "") == "OPENSEARCH_SERVERLESS"
  is_opensearch_managed    = local.is_vector && try(var.vector_config.storage_type, "") == "OPENSEARCH_MANAGED_CLUSTER"

  # S3 Vectors — derive names from var.name when the caller doesn't override them
  s3v_bucket_name = local.is_s3_vectors ? coalesce(try(var.vector_config.s3_vectors.vector_bucket_name, null), var.name) : null
  s3v_index_name  = local.is_s3_vectors ? coalesce(try(var.vector_config.s3_vectors.index_name, null), var.name) : null

  # OpenSearch Serverless — AWS limits collection names to 32 chars; policy names to 32 chars
  # Cap at 28 for the policy base so there's room for the "-enc" / "-net" / "-acc" suffix.
  oss_collection_name = local.is_opensearch_serverless ? substr(
    coalesce(try(var.vector_config.opensearch_serverless.collection_name, null), var.name), 0, 32
  ) : null
  oss_policy_base = local.is_opensearch_serverless ? substr(
    coalesce(try(var.vector_config.opensearch_serverless.collection_name, null), var.name), 0, 28
  ) : null
  oss_index_name = local.is_opensearch_serverless ? coalesce(
    try(var.vector_config.opensearch_serverless.vector_index_name, null), var.name
  ) : null
  oss_kms_key = local.is_opensearch_serverless ? try(var.vector_config.opensearch_serverless.kms_key_arn, null) : null
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

    precondition {
      condition     = !local.is_s3_vectors || try(var.vector_config.s3_vectors != null && var.vector_config.s3_vectors.dimension > 0, false)
      error_message = "vector_config.s3_vectors.dimension must be a positive integer when storage_type = S3_VECTORS."
    }
  }
}

# ── S3 Vectors (auto-created when storage_type = S3_VECTORS) ─────────────────

resource "aws_s3vectors_vector_bucket" "this" {
  count              = local.is_s3_vectors ? 1 : 0
  vector_bucket_name = local.s3v_bucket_name
  tags               = merge(var.tags, try(var.vector_config.s3_vectors.tags, {}))

  depends_on = [terraform_data.validations]
}

resource "aws_s3vectors_index" "this" {
  count              = local.is_s3_vectors ? 1 : 0
  index_name         = local.s3v_index_name
  vector_bucket_name = aws_s3vectors_vector_bucket.this[0].vector_bucket_name
  data_type          = try(var.vector_config.s3_vectors.data_type, "float32")
  dimension          = var.vector_config.s3_vectors.dimension
  distance_metric    = try(var.vector_config.s3_vectors.distance_metric, "euclidean")
}

# ── OpenSearch Serverless (auto-created when storage_type = OPENSEARCH_SERVERLESS) ──
# Note: the vector index inside the collection must be created separately using
# the opensearch Terraform provider or the OpenSearch API after this module runs.
# This module creates the collection and all required security/network/data-access policies.

resource "aws_opensearchserverless_security_policy" "encryption" {
  count       = local.is_opensearch_serverless ? 1 : 0
  name        = "${local.oss_policy_base}-enc"
  type        = "encryption"
  description = "Encryption policy for OpenSearch collection ${local.oss_collection_name}."
  policy = jsonencode(merge(
    {
      Rules       = [{ Resource = ["collection/${local.oss_collection_name}"], ResourceType = "collection" }]
      AWSOwnedKey = local.oss_kms_key == null
    },
    local.oss_kms_key != null ? { KmsARN = local.oss_kms_key } : {}
  ))

  depends_on = [terraform_data.validations]
}

resource "aws_opensearchserverless_security_policy" "network" {
  count       = local.is_opensearch_serverless ? 1 : 0
  name        = "${local.oss_policy_base}-net"
  type        = "network"
  description = "Network policy for OpenSearch collection ${local.oss_collection_name}."
  policy = jsonencode([{
    Rules = [
      { Resource = ["collection/${local.oss_collection_name}"], ResourceType = "collection" },
      { Resource = ["collection/${local.oss_collection_name}"], ResourceType = "dashboard" },
    ]
    AllowFromPublic = try(var.vector_config.opensearch_serverless.public_access, true)
  }])

  depends_on = [terraform_data.validations]
}

resource "aws_opensearchserverless_collection" "this" {
  count       = local.is_opensearch_serverless ? 1 : 0
  name        = local.oss_collection_name
  type        = "VECTORSEARCH"
  description = try(var.vector_config.opensearch_serverless.description, null)
  tags        = merge(var.tags, try(var.vector_config.opensearch_serverless.tags, {}))

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]
}

resource "aws_opensearchserverless_access_policy" "this" {
  count       = local.is_opensearch_serverless ? 1 : 0
  name        = "${local.oss_policy_base}-acc"
  type        = "data"
  description = "Data access policy for OpenSearch collection ${local.oss_collection_name}."
  policy = jsonencode([{
    Rules = [
      {
        Resource     = ["index/${local.oss_collection_name}/*"]
        Permission   = ["aoss:CreateIndex", "aoss:DeleteIndex", "aoss:UpdateIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:WriteDocument"]
        ResourceType = "index"
      },
      {
        Resource     = ["collection/${local.oss_collection_name}"]
        Permission   = ["aoss:DescribeCollectionItems"]
        ResourceType = "collection"
      },
    ]
    Principal = concat([var.role_arn], try(var.vector_config.opensearch_serverless.data_access_principals, []))
  }])

  depends_on = [terraform_data.validations]
}

# ── Knowledge Base ────────────────────────────────────────────────────────────

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
        for_each = local.is_opensearch_serverless ? [1] : []
        content {
          collection_arn    = aws_opensearchserverless_collection.this[0].arn
          vector_index_name = local.oss_index_name

          field_mapping {
            metadata_field = try(var.vector_config.opensearch_serverless.field_mapping.metadata_field, "AMAZON_BEDROCK_METADATA")
            text_field     = try(var.vector_config.opensearch_serverless.field_mapping.text_field, "AMAZON_BEDROCK_TEXT_CHUNK")
            vector_field   = try(var.vector_config.opensearch_serverless.field_mapping.vector_field, "bedrock-knowledge-base-default-vector")
          }
        }
      }

      dynamic "opensearch_managed_cluster_configuration" {
        for_each = local.is_opensearch_managed ? [1] : []
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
        for_each = local.is_s3_vectors ? [1] : []
        content {
          index_arn = aws_s3vectors_index.this[0].index_arn
        }
      }
    }
  }

  depends_on = [
    terraform_data.validations,
    aws_opensearchserverless_access_policy.this,
    aws_s3vectors_index.this,
  ]
}
