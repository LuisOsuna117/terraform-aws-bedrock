provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base = true
  knowledge_base_config = {
    name     = var.knowledge_base_name
    role_arn = var.knowledge_base_role_arn
    type     = "VECTOR"

    embedding_model_arn         = var.embedding_model_arn
    vector_embedding_dimensions = var.vector_embedding_dimensions
    storage_type                = "RDS"

    # aurora-pgvector — auto-created by the module
    rds = {
      vpc_id                     = var.vpc_id
      subnet_ids                 = var.subnet_ids
      cluster_identifier         = var.cluster_identifier
      database_name              = var.database_name
      allowed_security_group_ids = var.allowed_security_group_ids
      allowed_cidr_blocks        = var.allowed_cidr_blocks
      tags                       = var.tags
    }

    tags = var.tags
  }
}

# ── Post-apply SQL setup ────────────────────────────────────────────────────────
# After `tofu apply`, connect to the Aurora cluster and run once:
#
#   CREATE EXTENSION IF NOT EXISTS vector;
#   CREATE SCHEMA IF NOT EXISTS bedrock_integration;
#   CREATE TABLE bedrock_integration.bedrock_kb (
#     id              uuid PRIMARY KEY,
#     embedding       vector(1024),   -- match vector_embedding_dimensions
#     chunks          text,
#     metadata        json
#   );
#
# Use the credentials from module.bedrock.rds_secret_arn (Secrets Manager).
# The cluster endpoint is module.bedrock.rds_cluster_endpoint.
