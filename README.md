# terraform-aws-bedrock

Terraform wrapper module for Amazon Bedrock resources.

Current scope:

- root module is an orchestration wrapper
- `modules/knowledge_base` contains the actual Bedrock Knowledge Base implementation
- `modules/guardrail` contains the actual Bedrock Guardrail implementation
- current supported features are:
  - a `VECTOR` knowledge base backed by `S3_VECTORS`
  - a Bedrock guardrail with optional published version support

This keeps the repository aligned with a multi-resource layout while still making the knowledge base path usable today.

## Architecture

- Root module:
  - shared wrapper entrypoint
  - top-level `create`
  - feature flag `create_knowledge_base`
  - feature flag `create_guardrail`
  - nested `knowledge_base` config object
- nested `guardrail` config object
- Submodules:
  - [`modules/knowledge_base`](./modules/knowledge_base)
  - full IAM + S3 Vectors + Bedrock knowledge base implementation
  - [`modules/guardrail`](./modules/guardrail)
  - Bedrock guardrail and optional guardrail version implementation

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 6.27`

Provider `>= 6.27` is required because it includes the S3 Vectors resources and Bedrock knowledge base support for `storage_configuration.s3_vectors_configuration`.

## Root Wrapper Example

```hcl
provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "./"

  name                  = "example-bedrock"
  create_knowledge_base = true

  knowledge_base = {
    description = "Managed Bedrock knowledge base backed by S3 Vectors"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

## Root Wrapper BYO Example

```hcl
provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "./"

  name                  = "example-bedrock"
  create_knowledge_base = true

  knowledge_base = {
    create_role          = false
    create_vector_bucket = false
    create_vector_index  = false

    role_arn = aws_iam_role.bedrock_kb.arn

    s3_vectors = {
      index_arn          = aws_s3vectors_index.this.index_arn
      vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
      dimension          = 1024
      distance_metric    = "cosine"
    }
  }
}
```

## Direct Submodule Example

If you only want one implementation without the wrapper, call the submodule directly:

```hcl
module "knowledge_base" {
  source = "./modules/knowledge_base"

  name = "example-bedrock-kb"
}
```

```hcl
module "guardrail" {
  source = "./modules/guardrail"

  name            = "example-guardrail"
  create_version  = true
  content_policy_config = {
    filters_config = [
      {
        type            = "HATE"
        input_strength  = "MEDIUM"
        output_strength = "MEDIUM"
      }
    ]
    tier_config = {
      tier_name = "STANDARD"
    }
  }
}
```

## Root Interface

Top-level wrapper inputs:

- `create`: top-level enable flag
- `name`: shared base name for child resources
- `tags`: shared tags merged into child resources
- `create_knowledge_base`: enable the knowledge base submodule
- `create_guardrail`: enable the guardrail submodule
- `knowledge_base`: nested config forwarded to `modules/knowledge_base`
- `guardrail`: nested config forwarded to `modules/guardrail`

## Knowledge Base Interface

The `knowledge_base` object supports:

- `name`
- `description`
- `create_role`
- `create_vector_bucket`
- `create_vector_index`
- `role_arn`
- `embedding_model_arn`
- `supplemental_data_storage_s3_uri`
- `iam_role`
- `iam_role_additional_policy_documents`
- `s3_vectors`
- `timeouts`
- `tags`

The common managed path only needs:

- wrapper `name`
- `create_knowledge_base = true`

Everything else has defaults inside `modules/knowledge_base`.

## Guardrail Interface

The `guardrail` object supports:

- `name`
- `create_version`
- `blocked_input_messaging`
- `blocked_outputs_messaging`
- `description`
- `kms_key_arn`
- `content_policy_config`
- `contextual_grounding_policy_config`
- `cross_region_config`
- `sensitive_information_policy_config`
- `topic_policy_config`
- `word_policy_config`
- `version_description`
- `version_skip_destroy`
- `timeouts`
- `version_timeouts`
- `tags`

The common managed path only needs:

- wrapper `name`
- `create_guardrail = true`

Guardrail block messages default to safe strings inside `modules/guardrail`, and `create_version` defaults to `false` so the module does not publish immutable versions unless you ask it to.

## Knowledge Base Defaults

The knowledge base submodule defaults to:

- Amazon Titan Text Embeddings V2 in the active region
- `S3_VECTORS`
- vector dimension `1024`
- distance metric `cosine`
- data type `float32`
- managed IAM role creation
- managed S3 Vectors bucket and index creation
- Bedrock-recommended non-filterable metadata keys:
  - `AMAZON_BEDROCK_TEXT`
  - `AMAZON_BEDROCK_METADATA`

## Outputs

Root wrapper outputs include:

- `knowledge_base_arn`
- `knowledge_base_id`
- `knowledge_base_name`
- `knowledge_base_role_arn`
- `knowledge_base_embedding_model_arn`
- `knowledge_base_vector_bucket_arn`
- `knowledge_base_vector_bucket_name`
- `knowledge_base_vector_index_arn`
- `knowledge_base_vector_index_name`
- `knowledge_base_vector_dimension`
- `knowledge_base_distance_metric`
- `knowledge_base_managed_role_arn`
- `knowledge_base_managed_role_name`
- `guardrail_id`
- `guardrail_arn`
- `guardrail_status`
- `guardrail_draft_version`
- `guardrail_published_version`
- `guardrail_created_at`

## Tradeoffs

- The wrapper intentionally keeps feature configs grouped so the root can grow into a multi-resource Bedrock module without flattening every submodule argument into the root namespace.
- The knowledge base implementation is opinionated around S3 Vectors for the common path rather than exposing every raw provider option.
- The guardrail implementation defaults `create_version` to `false` because published versions are immutable and easy to accumulate accidentally.
- Resource policies for S3 Vectors are not managed by default; identity-based IAM on the Bedrock role is the safer reusable default.
- Future Bedrock data source or ingestion permissions should be added through `iam_role_additional_policy_documents` or external attachments.

## Examples

- [Managed root wrapper example](./examples/complete)
- [Bring-your-own-resources root wrapper example](./examples/bring-your-own-resources)
- [Guardrail root wrapper example](./examples/guardrail)
- [Knowledge base submodule](./modules/knowledge_base)
- [Guardrail submodule](./modules/guardrail)
