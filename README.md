# terraform-aws-bedrock

Terraform/OpenTofu module scaffold for Amazon Bedrock resources with DX-first `create_*` flags.

This initial cut provides:
- `create_knowledge_base` wrapper for `aws_bedrockagent_knowledge_base`
- `create_prompt_management` wrapper for `aws_bedrockagent_prompt`
- `create_guardrail` wrapper for `aws_bedrock_guardrail`
- `create_prompt_bridge` outputs for passing Bedrock prompt references into external runtimes such as AgentCore

Both are optional and independently toggleable.

## Requirements

- Terraform `>= 1.8`
- AWS provider `>= 6.21`

## Quickstart

```hcl
provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "./"

  name = "my-bedrock"

  create_knowledge_base = true
  knowledge_base_config = {
    role_arn            = aws_iam_role.bedrock_kb.arn
    type                = "VECTOR"
    embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"

    vector_storage_type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless = {
      collection_arn    = aws_opensearchserverless_collection.kb.arn
      vector_index_name = "bedrock-kb-index"
      field_mapping = {
        metadata_field = "AMAZON_BEDROCK_METADATA"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        vector_field   = "bedrock-knowledge-base-default-vector"
      }
    }
  }

  create_prompt_management = true
  prompt_management_config = {
    name            = "my-prompt"
    default_variant = "default"

    variants = [
      {
        name          = "default"
        template_type = "TEXT"
        model_id      = "amazon.titan-text-express-v1"
        text_template = {
          text            = "Summarize {{topic}} in {{style}} style."
          input_variables = ["topic", "style"]
        }
        inference_text = {
          temperature = 0.3
          max_tokens  = 512
        }
      }
    ]
  }
}
```

## Prompt Bridge

The prompt bridge is intentionally output-only.

- It does not create IAM resources.
- It resolves a prompt ID, ARN, and version from either:
  - `create_prompt_management = true`, or
  - `prompt_bridge_config.existing_prompt_id` / `existing_prompt_arn`
- It emits `prompt_bridge_environment_variables` so another module or runtime can consume the prompt reference cleanly.

Example:

```hcl
module "bedrock" {
  source = "./"

  name = "my-bedrock"

  create_prompt_management = true
  prompt_management_config = {
    name = "system-prompt"
    variants = [
      {
        name          = "default"
        template_type = "TEXT"
        model_id      = "amazon.titan-text-express-v1"
        text_template = {
          text = "You are a helpful assistant for {{tenant}}."
          input_variables = ["tenant"]
        }
      }
    ]
  }

  create_prompt_bridge = true
  prompt_bridge_config = {}
}
```

The bridge outputs are:

- `prompt_bridge_prompt_id`
- `prompt_bridge_prompt_arn`
- `prompt_bridge_prompt_version`
- `prompt_bridge_environment_variables`

## Design Notes

- Root module does orchestration only.
- Submodules are callable directly:
  - `modules/guardrail`
  - `modules/knowledge_base`
  - `modules/prompt_management`
- Validations fail early when a `create_*` flag is true and required config is missing.
- Common tags are merged automatically with module metadata tags.
- Prompt bridge is reference/output-only and assumes IAM is managed outside this module.
- Prompt management currently creates one Bedrock prompt resource per module invocation; use variants for alternate forms of the same prompt.

## Knowledge Base Scope (Current)

Supported `knowledge_base_type` values in this module version:
- `VECTOR`
- `KENDRA`

Supported vector storage backends in this module version:
- `OPENSEARCH_SERVERLESS`
- `OPENSEARCH_MANAGED_CLUSTER`
- `S3_VECTORS`

This keeps the interface approachable while covering common real-world patterns. SQL and additional vector stores can be added in follow-up iterations.

## Prompt Management Scope (Current)

Supported variant template types:
- `TEXT`
- `CHAT`

Current module supports:
- variant metadata
- text inference configuration
- optional agent generative resource reference
- text and chat template basics

Tool configuration in chat templates is intentionally left for a follow-up iteration to keep first delivery focused.

## Guardrail Scope (Current)

Current guardrail support includes:
- blocked input and output messaging
- content policy configuration
- contextual grounding policy configuration
- cross-region routing configuration
- sensitive information policy configuration
- topic policy configuration
- word policy configuration
- optional KMS key and tags

## Outputs

Root module outputs currently include:

- `knowledge_base_id`
- `knowledge_base_arn`
- `knowledge_base_name`
- `prompt_id`
- `prompt_arn`
- `prompt_name`
- `prompt_version`
- `prompt_bridge_prompt_id`
- `prompt_bridge_prompt_arn`
- `prompt_bridge_prompt_version`
- `prompt_bridge_environment_variables`
- `guardrail_id`
- `guardrail_arn`
- `guardrail_version`
- `guardrail_status`

Outputs are `null` when the corresponding `create_*` flag is disabled.

## Examples

- `examples/knowledge-base-kendra` for a Kendra-backed knowledge base.
- `examples/knowledge-base-opensearch-serverless` for a VECTOR knowledge base on OpenSearch Serverless.
- `examples/knowledge-base-opensearch-managed-cluster` for a VECTOR knowledge base on OpenSearch Managed Cluster.
- `examples/knowledge-base-s3-vectors` for a VECTOR knowledge base on S3 Vectors.
- `examples/guardrail` for an Amazon Bedrock guardrail.
- `examples/prompt-management` for a Bedrock prompt management resource.