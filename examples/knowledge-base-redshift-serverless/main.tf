provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_knowledge_base   = true
  knowledge_base_name     = var.knowledge_base_name
  knowledge_base_role_arn = var.knowledge_base_role_arn
  knowledge_base_type     = "SQL"
  knowledge_base_tags     = var.tags

  # Redshift Serverless — auto-created by the module
  redshift = {
    vpc_id                     = var.vpc_id
    subnet_ids                 = var.subnet_ids
    namespace_name             = var.namespace_name
    workgroup_name             = var.workgroup_name
    database_name              = var.database_name
    base_capacity              = var.base_capacity
    allowed_security_group_ids = var.allowed_security_group_ids
    allowed_cidr_blocks        = var.allowed_cidr_blocks
    tags                       = var.tags
  }
}

# ── Post-apply SQL setup ────────────────────────────────────────────────────────
# After `tofu apply`, connect to the Redshift workgroup and run once:
#
#   CREATE TABLE bedrock_kb_docs (
#     doc_id      VARCHAR(1024) NOT NULL,
#     chunk_text  VARCHAR(65535),
#     source_url  VARCHAR(2048),
#     PRIMARY KEY (doc_id)
#   );
#
# Use the admin credentials from module.bedrock.redshift_admin_secret_arn.
# Workgroup endpoint: module.bedrock.redshift_workgroup_endpoint
#
# The KB role (var.knowledge_base_role_arn) also needs:
#   redshift-serverless:GetCredentials on the workgroup ARN
#   redshift-data:BatchExecuteStatement, DescribeStatement, GetStatementResult
