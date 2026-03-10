locals {
  is_vector                = var.knowledge_base_type == "VECTOR"
  is_kendra                = var.knowledge_base_type == "KENDRA"
  is_sql                   = var.knowledge_base_type == "SQL"
  is_s3_vectors            = local.is_vector && var.storage_type == "S3_VECTORS"
  is_opensearch_serverless = local.is_vector && var.storage_type == "OPENSEARCH_SERVERLESS"
  is_opensearch_managed    = local.is_vector && var.storage_type == "OPENSEARCH_MANAGED_CLUSTER"
  is_rds                   = local.is_vector && var.storage_type == "RDS"
  is_redshift              = local.is_sql

  # S3 Vectors — derive names from var.name when the caller doesn't override them
  s3v_bucket_name = local.is_s3_vectors ? coalesce(try(var.s3_vectors.vector_bucket_name, null), var.name) : null
  s3v_index_name  = local.is_s3_vectors ? coalesce(try(var.s3_vectors.index_name, null), var.name) : null

  # OpenSearch Serverless — AWS limits collection names to 32 chars; policy names to 32 chars
  # Cap at 28 for the policy base so there's room for the "-enc" / "-net" / "-acc" suffix.
  oss_collection_name = local.is_opensearch_serverless ? substr(
    coalesce(try(var.opensearch_serverless.collection_name, null), var.name), 0, 32
  ) : null
  oss_policy_base = local.is_opensearch_serverless ? substr(
    coalesce(try(var.opensearch_serverless.collection_name, null), var.name), 0, 28
  ) : null
  oss_index_name = local.is_opensearch_serverless ? coalesce(
    try(var.opensearch_serverless.vector_index_name, null), var.name
  ) : null
  oss_kms_key = local.is_opensearch_serverless ? try(var.opensearch_serverless.kms_key_arn, null) : null

  # Aurora PostgreSQL
  rds_identifier = local.is_rds ? coalesce(try(var.rds.cluster_identifier, null), var.name) : null

  # Redshift Serverless
  rs_namespace = local.is_redshift ? coalesce(try(var.redshift.namespace_name, null), var.name) : null
  rs_workgroup = local.is_redshift ? coalesce(try(var.redshift.workgroup_name, null), var.name) : null
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !local.is_vector || try(trimspace(var.embedding_model_arn) != "", false)
      error_message = "embedding_model_arn must be provided when knowledge_base_type = VECTOR."
    }

    precondition {
      condition     = !local.is_kendra || try(trimspace(var.kendra_index_arn) != "", false)
      error_message = "kendra_index_arn must be provided when knowledge_base_type = KENDRA."
    }

    precondition {
      condition     = !local.is_s3_vectors || try(var.s3_vectors != null && var.s3_vectors.dimension > 0, false)
      error_message = "s3_vectors.dimension must be a positive integer when storage_type = S3_VECTORS."
    }

    precondition {
      condition     = !local.is_rds || try(var.rds != null && length(var.rds.subnet_ids) > 0, false)
      error_message = "rds.subnet_ids must be set when storage_type = RDS."
    }

    precondition {
      condition     = !local.is_rds || try(trimspace(var.rds.vpc_id) != "", false)
      error_message = "rds.vpc_id must be set when storage_type = RDS."
    }

    precondition {
      condition     = !local.is_redshift || var.redshift != null
      error_message = "redshift must be provided when knowledge_base_type = SQL."
    }

    precondition {
      condition     = !local.is_redshift || try(length(var.redshift.subnet_ids) > 0, false)
      error_message = "redshift.subnet_ids must be set when knowledge_base_type = SQL."
    }

    precondition {
      condition     = !local.is_redshift || try(trimspace(var.redshift.vpc_id) != "", false)
      error_message = "redshift.vpc_id must be set when knowledge_base_type = SQL."
    }
  }
}

# ── S3 Vectors (auto-created when storage_type = S3_VECTORS) ─────────────────

resource "aws_s3vectors_vector_bucket" "this" {
  count              = local.is_s3_vectors ? 1 : 0
  vector_bucket_name = local.s3v_bucket_name
  tags               = merge(var.tags, var.s3_vectors.tags)

  depends_on = [terraform_data.validations]
}

resource "aws_s3vectors_index" "this" {
  count              = local.is_s3_vectors ? 1 : 0
  index_name         = local.s3v_index_name
  vector_bucket_name = aws_s3vectors_vector_bucket.this[0].vector_bucket_name
  data_type          = var.s3_vectors.data_type
  dimension          = var.s3_vectors.dimension
  distance_metric    = var.s3_vectors.distance_metric
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
    AllowFromPublic = var.opensearch_serverless.public_access
  }])

  depends_on = [terraform_data.validations]
}

resource "aws_opensearchserverless_collection" "this" {
  count       = local.is_opensearch_serverless ? 1 : 0
  name        = local.oss_collection_name
  type        = "VECTORSEARCH"
  description = var.opensearch_serverless.description
  tags        = merge(var.tags, var.opensearch_serverless.tags)

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
    Principal = concat([var.role_arn], var.opensearch_serverless.data_access_principals)
  }])

  depends_on = [terraform_data.validations]
}

# ── Aurora PostgreSQL + pgvector (auto-created when storage_type = RDS) ───────
# After apply, connect to the cluster and run:
#   CREATE EXTENSION IF NOT EXISTS vector;
#   CREATE SCHEMA IF NOT EXISTS bedrock_integration;
#   CREATE TABLE bedrock_integration.bedrock_kb (
#     id uuid PRIMARY KEY,
#     embedding vector(<dimensions>),
#     chunks text,
#     metadata json
#   );
# Table name and field names are configurable via vector_config.rds.table_name
# and vector_config.rds.field_metadata / field_text / field_vector / field_primary_key.
# The KB role (var.role_arn) needs rds-data:ExecuteStatement,
# rds-data:BatchExecuteStatement, and secretsmanager:GetSecretValue permissions.

resource "aws_db_subnet_group" "this" {
  count      = local.is_rds ? 1 : 0
  name       = local.rds_identifier
  subnet_ids = var.rds.subnet_ids
  tags       = merge(var.tags, var.rds.tags)

  depends_on = [terraform_data.validations]
}

resource "aws_security_group" "rds" {
  count       = local.is_rds ? 1 : 0
  name        = "${local.rds_identifier}-rds"
  description = "Security group for Aurora PostgreSQL KB cluster ${local.rds_identifier}."
  vpc_id      = var.rds.vpc_id

  dynamic "ingress" {
    for_each = length(var.rds.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "PostgreSQL from allowed CIDRs."
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.rds.allowed_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = length(var.rds.allowed_security_group_ids) > 0 ? [1] : []
    content {
      description     = "PostgreSQL from allowed security groups."
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = var.rds.allowed_security_group_ids
    }
  }

  dynamic "egress" {
    for_each = length(var.rds.allowed_egress_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Outbound to specified CIDRs."
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.rds.allowed_egress_cidr_blocks
    }
  }

  tags       = merge(var.tags, var.rds.tags)
  depends_on = [terraform_data.validations]
}

resource "aws_rds_cluster" "this" {
  count = local.is_rds ? 1 : 0

  cluster_identifier          = local.rds_identifier
  engine                      = "aurora-postgresql"
  engine_mode                 = "provisioned"
  engine_version              = var.rds.engine_version
  database_name               = var.rds.database_name
  master_username             = var.rds.master_username
  manage_master_user_password = true
  storage_encrypted           = true
  kms_key_id                  = var.rds.kms_key_id
  enable_http_endpoint        = true # required for Bedrock RDS Data API access

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]

  serverlessv2_scaling_configuration {
    min_capacity = var.rds.min_capacity
    max_capacity = var.rds.max_capacity
  }

  backup_retention_period = var.rds.backup_retention_period
  deletion_protection     = var.rds.deletion_protection
  skip_final_snapshot     = var.rds.skip_final_snapshot
  tags                    = merge(var.tags, var.rds.tags)
}

resource "aws_rds_cluster_instance" "this" {
  count = local.is_rds ? 1 : 0

  identifier         = "${local.rds_identifier}-writer"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this[0].engine
  engine_version     = aws_rds_cluster.this[0].engine_version

  performance_insights_enabled          = var.rds.performance_insights_enabled
  performance_insights_kms_key_id       = var.rds.performance_insights_kms_key_id
  performance_insights_retention_period = var.rds.performance_insights_enabled ? 7 : null

  tags = merge(var.tags, var.rds.tags)
}

# ── Redshift Serverless (auto-created when knowledge_base_type = SQL) ──────────
# After apply, connect to the workgroup and create the schema/tables that Bedrock
# will query. The KB role (var.role_arn) needs:
#   redshift-serverless:GetCredentials on the workgroup
#   redshift-data:BatchExecuteStatement, redshift-data:DescribeStatement,
#   redshift-data:GetStatementResult on the workgroup

resource "aws_security_group" "redshift" {
  count       = local.is_redshift ? 1 : 0
  name        = "${local.rs_workgroup}-rs"
  description = "Security group for Redshift Serverless workgroup ${local.rs_workgroup}."
  vpc_id      = var.redshift.vpc_id

  dynamic "ingress" {
    for_each = length(var.redshift.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Redshift from allowed CIDRs."
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = var.redshift.allowed_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = length(var.redshift.allowed_security_group_ids) > 0 ? [1] : []
    content {
      description     = "Redshift from allowed security groups."
      from_port       = 5439
      to_port         = 5439
      protocol        = "tcp"
      security_groups = var.redshift.allowed_security_group_ids
    }
  }

  dynamic "egress" {
    for_each = length(var.redshift.allowed_egress_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Outbound to specified CIDRs."
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.redshift.allowed_egress_cidr_blocks
    }
  }

  tags       = merge(var.tags, var.redshift.tags)
  depends_on = [terraform_data.validations]
}

resource "aws_redshiftserverless_namespace" "this" {
  count = local.is_redshift ? 1 : 0

  namespace_name        = local.rs_namespace
  db_name               = var.redshift.database_name
  admin_username        = var.redshift.admin_username
  manage_admin_password = true
  tags                  = merge(var.tags, var.redshift.tags)

  depends_on = [terraform_data.validations]
}

resource "aws_redshiftserverless_workgroup" "this" {
  count = local.is_redshift ? 1 : 0

  namespace_name      = aws_redshiftserverless_namespace.this[0].namespace_name
  workgroup_name      = local.rs_workgroup
  base_capacity       = var.redshift.base_capacity
  subnet_ids          = var.redshift.subnet_ids
  security_group_ids  = [aws_security_group.redshift[0].id]
  publicly_accessible = var.redshift.publicly_accessible
  tags                = merge(var.tags, var.redshift.tags)
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
        embedding_model_arn = var.embedding_model_arn

        dynamic "embedding_model_configuration" {
          for_each = var.vector_embedding_dimensions != null || var.vector_embedding_data_type != null ? [1] : []
          content {
            bedrock_embedding_model_configuration {
              dimensions          = var.vector_embedding_dimensions
              embedding_data_type = var.vector_embedding_data_type
            }
          }
        }

        dynamic "supplemental_data_storage_configuration" {
          for_each = var.supplemental_s3_uri != null ? [1] : []
          content {
            storage_location {
              type = "S3"
              s3_location {
                uri = var.supplemental_s3_uri
              }
            }
          }
        }
      }
    }

    dynamic "kendra_knowledge_base_configuration" {
      for_each = local.is_kendra ? [1] : []
      content {
        kendra_index_arn = var.kendra_index_arn
      }
    }

    dynamic "sql_knowledge_base_configuration" {
      for_each = local.is_sql ? [1] : []
      content {
        type = "REDSHIFT"
        redshift_configuration {
          query_engine_configuration {
            type = "SERVERLESS"
            serverless_configuration {
              workgroup_arn = aws_redshiftserverless_workgroup.this[0].arn
            }
          }

          storage_configuration {
            type = "REDSHIFT"
            redshift_configuration {
              database_name = var.redshift.database_name
            }
          }
        }
      }
    }
  }

  dynamic "storage_configuration" {
    for_each = local.is_vector ? [1] : []
    content {
      type = var.storage_type

      dynamic "opensearch_serverless_configuration" {
        for_each = local.is_opensearch_serverless ? [1] : []
        content {
          collection_arn    = aws_opensearchserverless_collection.this[0].arn
          vector_index_name = local.oss_index_name

          field_mapping {
            metadata_field = var.opensearch_serverless.field_metadata
            text_field     = var.opensearch_serverless.field_text
            vector_field   = var.opensearch_serverless.field_vector
          }
        }
      }

      dynamic "opensearch_managed_cluster_configuration" {
        for_each = local.is_opensearch_managed ? [1] : []
        content {
          domain_arn        = var.opensearch_managed_cluster.domain_arn
          domain_endpoint   = var.opensearch_managed_cluster.domain_endpoint
          vector_index_name = var.opensearch_managed_cluster.vector_index_name

          field_mapping {
            metadata_field = var.opensearch_managed_cluster.field_metadata
            text_field     = var.opensearch_managed_cluster.field_text
            vector_field   = var.opensearch_managed_cluster.field_vector
          }
        }
      }

      dynamic "s3_vectors_configuration" {
        for_each = local.is_s3_vectors ? [1] : []
        content {
          index_arn = aws_s3vectors_index.this[0].index_arn
        }
      }

      dynamic "rds_configuration" {
        for_each = local.is_rds ? [1] : []
        content {
          credentials_secret_arn = aws_rds_cluster.this[0].master_user_secret[0].secret_arn
          database_name          = var.rds.database_name
          resource_arn           = aws_rds_cluster.this[0].arn
          table_name             = var.rds.table_name

          field_mapping {
            metadata_field    = var.rds.field_metadata
            primary_key_field = var.rds.field_primary_key
            text_field        = var.rds.field_text
            vector_field      = var.rds.field_vector
          }
        }
      }
    }
  }

  depends_on = [
    terraform_data.validations,
    aws_opensearchserverless_access_policy.this,
    aws_s3vectors_index.this,
    aws_rds_cluster_instance.this,
    aws_redshiftserverless_workgroup.this,
  ]
}
