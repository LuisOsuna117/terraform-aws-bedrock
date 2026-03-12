provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  name                         = "example-bedrock-kb-byo"
  name_slug_base               = trim(replace(lower(local.name), "/[^a-z0-9-]/", "-"), "-")
  name_slug                    = length(local.name_slug_base) > 0 ? local.name_slug_base : "kb"
  vector_bucket_prefix_length  = max(1, 63 - 1 - length(data.aws_caller_identity.current.account_id))
  vector_bucket_name           = join("-", [substr(local.name_slug, 0, min(length(local.name_slug), local.vector_bucket_prefix_length)), data.aws_caller_identity.current.account_id])
  vector_index_name_base       = "${local.name_slug}-index"
  vector_index_name            = trim(substr(local.vector_index_name_base, 0, min(length(local.vector_index_name_base), 63)), "-.")
  embedding_model_arn          = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}::foundation-model/amazon.titan-embed-text-v2:0"
  non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
}

resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = local.vector_bucket_name

  tags = {
    Example = "bring-your-own-resources"
  }
}

resource "aws_s3vectors_index" "this" {
  index_name         = local.vector_index_name
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
  data_type          = "float32"
  dimension          = 1024
  distance_metric    = "cosine"

  metadata_configuration {
    non_filterable_metadata_keys = local.non_filterable_metadata_keys
  }

  tags = {
    Example = "bring-your-own-resources"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_slug}-bedrock-kb"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Example = "bring-your-own-resources"
  }
}

data "aws_iam_policy_document" "role" {
  statement {
    sid = "BedrockEmbeddingModelAccess"

    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [local.embedding_model_arn]
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

    resources = [aws_s3vectors_index.this.index_arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.name_slug}-bedrock-kb-inline"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.role.json
}

module "bedrock" {
  source = "../../"

  name                  = local.name
  create_knowledge_base = true

  knowledge_base = {
    create_role          = false
    create_vector_bucket = false
    create_vector_index  = false

    role_arn = aws_iam_role.this.arn

    s3_vectors = {
      index_arn          = aws_s3vectors_index.this.index_arn
      index_name         = aws_s3vectors_index.this.index_name
      vector_bucket_arn  = aws_s3vectors_vector_bucket.this.vector_bucket_arn
      vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
      dimension          = 1024
      distance_metric    = "cosine"
    }
  }

  tags = {
    Example = "bring-your-own-resources"
  }

  depends_on = [aws_iam_role_policy.this]
}
