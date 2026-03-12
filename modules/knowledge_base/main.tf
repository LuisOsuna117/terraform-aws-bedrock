data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  create               = var.create
  create_role          = var.create && var.create_role
  create_vector_bucket = var.create && var.create_vector_bucket
  create_vector_index  = var.create && var.create_vector_index

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  normalized_name = trimspace(var.name)

  name_slug_base       = trim(replace(lower(local.normalized_name), "/[^a-z0-9-]/", "-"), "-")
  name_slug            = length(local.name_slug_base) > 0 ? local.name_slug_base : "kb"
  index_name_slug_base = trim(replace(lower(local.normalized_name), "/[^a-z0-9.-]/", "-"), "-.")
  index_name_slug      = length(local.index_name_slug_base) > 0 ? local.index_name_slug_base : "kb"

  default_role_name_base = "${local.name_slug}-bedrock-kb"
  default_role_name      = trim(substr(local.default_role_name_base, 0, min(length(local.default_role_name_base), 64)), "-")

  default_vector_bucket_prefix_length = max(1, 63 - 1 - length(local.account_id))
  default_vector_bucket_name = join(
    "-",
    compact([
      trim(substr(local.name_slug, 0, min(length(local.name_slug), local.default_vector_bucket_prefix_length)), "-"),
      local.account_id,
    ])
  )

  default_vector_index_name_base = "${local.index_name_slug}-index"
  default_vector_index_name      = trim(substr(local.default_vector_index_name_base, 0, min(length(local.default_vector_index_name_base), 63)), "-.")

  requested_vector_bucket_name = coalesce(try(var.s3_vectors.vector_bucket_name, null), local.default_vector_bucket_name)
  requested_vector_index_name  = coalesce(try(var.s3_vectors.index_name, null), local.default_vector_index_name)

  existing_vector_bucket_name_from_arn       = try(split("/", var.s3_vectors.vector_bucket_arn)[1], null)
  existing_vector_bucket_name_from_index_arn = try(split("/", var.s3_vectors.index_arn)[1], null)
  existing_vector_index_name_from_arn        = try(split("/", var.s3_vectors.index_arn)[3], null)

  # When users pass names instead of ARNs, derive same-account/same-region S3 Vectors ARNs.
  resolved_vector_bucket_name = local.create_vector_bucket ? aws_s3vectors_vector_bucket.this[0].vector_bucket_name : coalesce(
    try(var.s3_vectors.vector_bucket_name, null),
    local.existing_vector_bucket_name_from_arn,
    local.existing_vector_bucket_name_from_index_arn,
  )
  resolved_vector_bucket_arn = local.create_vector_bucket ? aws_s3vectors_vector_bucket.this[0].vector_bucket_arn : coalesce(
    try(var.s3_vectors.vector_bucket_arn, null),
    local.resolved_vector_bucket_name != null ? "arn:${local.partition}:s3vectors:${local.region}:${local.account_id}:bucket/${local.resolved_vector_bucket_name}" : null,
  )
  resolved_vector_index_name = local.create_vector_index ? aws_s3vectors_index.this[0].index_name : coalesce(
    try(var.s3_vectors.index_name, null),
    local.existing_vector_index_name_from_arn,
  )
  resolved_vector_index_arn = local.create_vector_index ? aws_s3vectors_index.this[0].index_arn : coalesce(
    try(var.s3_vectors.index_arn, null),
    local.resolved_vector_bucket_name != null && local.resolved_vector_index_name != null ? "arn:${local.partition}:s3vectors:${local.region}:${local.account_id}:bucket/${local.resolved_vector_bucket_name}/index/${local.resolved_vector_index_name}" : null,
  )

  resolved_role_arn = local.create_role ? aws_iam_role.this[0].arn : var.role_arn

  resolved_embedding_model_arn = coalesce(
    var.embedding_model_arn,
    "arn:${local.partition}:bedrock:${local.region}::foundation-model/amazon.titan-embed-text-v2:0",
  )
  resolved_dimension           = try(var.s3_vectors.dimension, 1024)
  resolved_distance_metric     = lower(try(var.s3_vectors.distance_metric, "cosine"))
  resolved_vector_data_type    = lower(try(var.s3_vectors.data_type, "float32"))
  resolved_embedding_data_type = upper(local.resolved_vector_data_type)

  resolved_non_filterable_metadata_keys = distinct(try(var.s3_vectors.non_filterable_metadata_keys, [
    "AMAZON_BEDROCK_TEXT",
    "AMAZON_BEDROCK_METADATA",
  ]))

  role_name        = coalesce(try(var.iam_role.name, null), local.default_role_name)
  role_description = coalesce(try(var.iam_role.description, null), "Amazon Bedrock Knowledge Base service role for ${var.name}")
  role_policy_name = trim(substr("${local.role_name}-inline", 0, min(length("${local.role_name}-inline"), 128)), "-")

  role_tags   = merge(var.tags, try(var.iam_role.tags, {}))
  vector_tags = merge(var.tags, try(var.s3_vectors.tags, {}))

  bucket_encryption = try(var.s3_vectors.bucket_encryption, null)
  index_encryption  = try(var.s3_vectors.index_encryption, null)

  bucket_name_is_valid = can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])?$", local.requested_vector_bucket_name))
  index_name_is_valid  = can(regex("^[a-z0-9](?:[a-z0-9.-]{1,61}[a-z0-9])?$", local.requested_vector_index_name))

  timeouts_configured = length(compact([
    try(var.timeouts.create, null),
    try(var.timeouts.update, null),
    try(var.timeouts.delete, null),
  ])) > 0
}

resource "terraform_data" "validation" {
  input = null

  lifecycle {
    precondition {
      condition     = !local.create || var.create_role || try(length(trimspace(var.role_arn)) > 0, false)
      error_message = "Set role_arn when create_role = false."
    }

    precondition {
      condition     = !local.create || !var.create_vector_bucket || var.create_vector_index
      error_message = "create_vector_bucket requires create_vector_index so the managed bucket is used by the managed index."
    }

    precondition {
      condition     = !local.create || !var.create_vector_index || local.resolved_vector_bucket_name != null
      error_message = "Set s3_vectors.vector_bucket_name or s3_vectors.vector_bucket_arn when create_vector_index = true and create_vector_bucket = false."
    }

    precondition {
      condition     = !local.create || var.create_vector_index || local.resolved_vector_index_arn != null
      error_message = "Set s3_vectors.index_arn, or set both s3_vectors.index_name and s3_vectors.vector_bucket_name/vector_bucket_arn, when create_vector_index = false."
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_role ? 1 : 0

  statement {
    sid     = "AmazonBedrockKnowledgeBaseAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.partition}:bedrock:${local.region}:${local.account_id}:knowledge-base/*"]
    }
  }
}

data "aws_iam_policy_document" "role" {
  count = local.create_role ? 1 : 0

  source_policy_documents = var.iam_role_additional_policy_documents

  statement {
    sid = "BedrockEmbeddingModelAccess"

    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [local.resolved_embedding_model_arn]
  }

  statement {
    sid = "BedrockModelListing"

    actions = [
      "bedrock:ListCustomModels",
      "bedrock:ListFoundationModels",
    ]

    resources = ["*"]
  }

  statement {
    sid = "S3VectorsIndexAccess"

    actions = [
      "s3vectors:DeleteVectors",
      "s3vectors:GetIndex",
      "s3vectors:GetVectors",
      "s3vectors:PutVectors",
      "s3vectors:QueryVectors",
    ]

    resources = [local.resolved_vector_index_arn]
  }
}

resource "aws_iam_role" "this" {
  count = local.create_role ? 1 : 0

  name                 = local.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  description          = local.role_description
  max_session_duration = try(var.iam_role.max_session_duration, 3600)
  path                 = try(var.iam_role.path, "/")
  permissions_boundary = try(var.iam_role.permissions_boundary, null)
  tags                 = local.role_tags
}

resource "aws_iam_role_policy" "this" {
  count = local.create_role ? 1 : 0

  name   = local.role_policy_name
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.role[0].json
}

resource "aws_s3vectors_vector_bucket" "this" {
  count = local.create_vector_bucket ? 1 : 0

  vector_bucket_name = local.requested_vector_bucket_name
  force_destroy      = try(var.s3_vectors.force_destroy, false)
  tags               = local.vector_tags

  dynamic "encryption_configuration" {
    for_each = local.bucket_encryption == null ? [] : [local.bucket_encryption]

    content {
      sse_type    = try(encryption_configuration.value.sse_type, "AES256")
      kms_key_arn = try(encryption_configuration.value.kms_key_arn, null)
    }
  }

  lifecycle {
    precondition {
      condition     = local.bucket_name_is_valid
      error_message = "The resolved S3 Vectors bucket name must be 3-63 characters of lowercase letters, numbers, or hyphens."
    }
  }
}

resource "aws_s3vectors_index" "this" {
  count = local.create_vector_index ? 1 : 0

  index_name         = local.requested_vector_index_name
  vector_bucket_name = local.resolved_vector_bucket_name
  data_type          = local.resolved_vector_data_type
  dimension          = local.resolved_dimension
  distance_metric    = local.resolved_distance_metric
  tags               = local.vector_tags

  dynamic "encryption_configuration" {
    for_each = local.index_encryption == null ? [] : [local.index_encryption]

    content {
      sse_type    = try(encryption_configuration.value.sse_type, "AES256")
      kms_key_arn = try(encryption_configuration.value.kms_key_arn, null)
    }
  }

  dynamic "metadata_configuration" {
    for_each = length(local.resolved_non_filterable_metadata_keys) == 0 ? [] : [local.resolved_non_filterable_metadata_keys]

    content {
      non_filterable_metadata_keys = metadata_configuration.value
    }
  }

  lifecycle {
    precondition {
      condition     = local.index_name_is_valid
      error_message = "The resolved S3 Vectors index name must be 3-63 characters of lowercase letters, numbers, hyphens, or dots."
    }
  }
}

resource "aws_bedrockagent_knowledge_base" "this" {
  count = local.create ? 1 : 0

  name        = var.name
  description = var.description
  role_arn    = local.resolved_role_arn
  tags        = var.tags

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = local.resolved_embedding_model_arn

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = local.resolved_dimension
          embedding_data_type = local.resolved_embedding_data_type
        }
      }

      dynamic "supplemental_data_storage_configuration" {
        for_each = var.supplemental_data_storage_s3_uri == null ? [] : [var.supplemental_data_storage_s3_uri]

        content {
          storage_location {
            type = "S3"

            s3_location {
              uri = supplemental_data_storage_configuration.value
            }
          }
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      index_arn = local.resolved_vector_index_arn
    }
  }

  dynamic "timeouts" {
    for_each = local.timeouts_configured ? [var.timeouts] : []

    content {
      create = try(timeouts.value.create, null)
      delete = try(timeouts.value.delete, null)
      update = try(timeouts.value.update, null)
    }
  }

  lifecycle {
    precondition {
      condition     = local.resolved_role_arn != null
      error_message = "The knowledge base requires an IAM role ARN. Set role_arn or leave create_role = true."
    }

    precondition {
      condition     = local.resolved_vector_index_arn != null
      error_message = "The knowledge base requires a resolved S3 Vectors index ARN. Set create_vector_index = true or provide BYO index inputs."
    }
  }

  depends_on = [
    terraform_data.validation,
    aws_iam_role_policy.this,
    aws_s3vectors_index.this,
  ]
}
