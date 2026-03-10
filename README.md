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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.21 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_guardrail"></a> [guardrail](#module\_guardrail) | ./modules/guardrail | n/a |
| <a name="module_knowledge_base"></a> [knowledge\_base](#module\_knowledge\_base) | ./modules/knowledge_base | n/a |
| <a name="module_prompt_management"></a> [prompt\_management](#module\_prompt\_management) | ./modules/prompt_management | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_guardrail"></a> [create\_guardrail](#input\_create\_guardrail) | When true, creates an Amazon Bedrock guardrail using modules/guardrail. | `bool` | `false` | no |
| <a name="input_create_knowledge_base"></a> [create\_knowledge\_base](#input\_create\_knowledge\_base) | When true, creates a Bedrock knowledge base using modules/knowledge\_base. | `bool` | `false` | no |
| <a name="input_create_prompt_bridge"></a> [create\_prompt\_bridge](#input\_create\_prompt\_bridge) | When true, exposes resolved prompt references and environment variables for AgentCore/app runtimes. No IAM resources are created. | `bool` | `false` | no |
| <a name="input_create_prompt_management"></a> [create\_prompt\_management](#input\_create\_prompt\_management) | When true, creates a Bedrock prompt resource using modules/prompt\_management. | `bool` | `false` | no |
| <a name="input_guardrail_config"></a> [guardrail\_config](#input\_guardrail\_config) | Configuration object for the guardrail module. Required when create\_guardrail = true. | <pre>object({<br/>    name                      = optional(string)<br/>    blocked_input_messaging   = string<br/>    blocked_outputs_messaging = string<br/>    description               = optional(string)<br/>    kms_key_arn               = optional(string)<br/>    region                    = optional(string)<br/>    tags                      = optional(map(string), {})<br/>    content_policy_config = optional(object({<br/>      filters_config = optional(list(object({<br/>        input_action      = optional(string)<br/>        input_enabled     = optional(bool)<br/>        input_modalities  = optional(list(string))<br/>        input_strength    = optional(string)<br/>        output_action     = optional(string)<br/>        output_enabled    = optional(bool)<br/>        output_modalities = optional(list(string))<br/>        output_strength   = optional(string)<br/>        type              = optional(string)<br/>      })), [])<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    contextual_grounding_policy_config = optional(object({<br/>      filters_config = list(object({<br/>        threshold = number<br/>        type      = string<br/>      }))<br/>    }))<br/>    cross_region_config = optional(object({<br/>      guardrail_profile_identifier = string<br/>    }))<br/>    sensitive_information_policy_config = optional(object({<br/>      pii_entities_config = optional(list(object({<br/>        action         = string<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      regexes_config = optional(list(object({<br/>        action         = string<br/>        description    = optional(string)<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        name           = string<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        pattern        = string<br/>      })), [])<br/>    }))<br/>    topic_policy_config = optional(object({<br/>      topics_config = list(object({<br/>        definition = string<br/>        examples   = optional(list(string))<br/>        name       = string<br/>        type       = string<br/>      }))<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    word_policy_config = optional(object({<br/>      managed_word_lists_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      words_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        text           = string<br/>      })), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_knowledge_base_config"></a> [knowledge\_base\_config](#input\_knowledge\_base\_config) | Configuration object for the knowledge base module. Required when create\_knowledge\_base = true. | <pre>object({<br/>    name                        = optional(string)<br/>    description                 = optional(string)<br/>    role_arn                    = string<br/>    region                      = optional(string)<br/>    tags                        = optional(map(string), {})<br/>    type                        = optional(string, "VECTOR")<br/>    embedding_model_arn         = optional(string)<br/>    vector_embedding_dimensions = optional(number)<br/>    vector_embedding_data_type  = optional(string)<br/>    supplemental_s3_uri         = optional(string)<br/>    kendra_index_arn            = optional(string)<br/>    vector_storage_type         = optional(string)<br/><br/>    opensearch_serverless = optional(object({<br/>      collection_arn    = string<br/>      vector_index_name = string<br/>      field_mapping = object({<br/>        metadata_field = string<br/>        text_field     = string<br/>        vector_field   = string<br/>      })<br/>    }))<br/><br/>    opensearch_managed_cluster = optional(object({<br/>      domain_arn        = string<br/>      domain_endpoint   = string<br/>      vector_index_name = string<br/>      field_mapping = object({<br/>        metadata_field = string<br/>        text_field     = string<br/>        vector_field   = string<br/>      })<br/>    }))<br/><br/>    s3_vectors = optional(object({<br/>      index_arn         = optional(string)<br/>      index_name        = optional(string)<br/>      vector_bucket_arn = optional(string)<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used as a prefix for resources when per-module names are not explicitly set. | `string` | n/a | yes |
| <a name="input_prompt_bridge_config"></a> [prompt\_bridge\_config](#input\_prompt\_bridge\_config) | Bridge configuration for reusing Bedrock Prompt Management from external runtimes (such as AgentCore apps). | <pre>object({<br/>    existing_prompt_arn = optional(string)<br/>    existing_prompt_id  = optional(string)<br/>    prompt_version      = optional(string)<br/>    env_var_names = optional(object({<br/>      prompt_id      = optional(string, "BEDROCK_PROMPT_ID")<br/>      prompt_arn     = optional(string, "BEDROCK_PROMPT_ARN")<br/>      prompt_version = optional(string, "BEDROCK_PROMPT_VERSION")<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_prompt_management_config"></a> [prompt\_management\_config](#input\_prompt\_management\_config) | Configuration object for the prompt management module. Required when create\_prompt\_management = true. | <pre>object({<br/>    name                        = optional(string)<br/>    description                 = optional(string)<br/>    default_variant             = optional(string)<br/>    customer_encryption_key_arn = optional(string)<br/>    region                      = optional(string)<br/>    tags                        = optional(map(string), {})<br/>    variants = optional(list(object({<br/>      name                            = string<br/>      template_type                   = string<br/>      model_id                        = optional(string)<br/>      additional_model_request_fields = optional(map(any))<br/>      metadata                        = optional(map(string))<br/>      gen_ai_agent_identifier         = optional(string)<br/>      inference_text = optional(object({<br/>        max_tokens     = optional(number)<br/>        stop_sequences = optional(list(string))<br/>        temperature    = optional(number)<br/>        top_p          = optional(number)<br/>      }))<br/>      text_template = optional(object({<br/>        text             = string<br/>        input_variables  = optional(list(string), [])<br/>        cache_point_type = optional(string)<br/>      }))<br/>      chat_template = optional(object({<br/>        input_variables = optional(list(string), [])<br/>        messages = optional(list(object({<br/>          role             = string<br/>          text             = optional(string)<br/>          cache_point_type = optional(string)<br/>        })), [])<br/>        system_prompts = optional(list(object({<br/>          text             = optional(string)<br/>          cache_point_type = optional(string)<br/>        })), [])<br/>      }))<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto all resources managed by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guardrail_arn"></a> [guardrail\_arn](#output\_guardrail\_arn) | Guardrail ARN. Null when create\_guardrail = false. |
| <a name="output_guardrail_id"></a> [guardrail\_id](#output\_guardrail\_id) | Guardrail ID. Null when create\_guardrail = false. |
| <a name="output_guardrail_status"></a> [guardrail\_status](#output\_guardrail\_status) | Guardrail status. Null when create\_guardrail = false. |
| <a name="output_guardrail_version"></a> [guardrail\_version](#output\_guardrail\_version) | Guardrail version. Null when create\_guardrail = false. |
| <a name="output_knowledge_base_arn"></a> [knowledge\_base\_arn](#output\_knowledge\_base\_arn) | Knowledge base ARN. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_id"></a> [knowledge\_base\_id](#output\_knowledge\_base\_id) | Knowledge base ID. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_name"></a> [knowledge\_base\_name](#output\_knowledge\_base\_name) | Knowledge base name. Null when create\_knowledge\_base = false. |
| <a name="output_prompt_arn"></a> [prompt\_arn](#output\_prompt\_arn) | Prompt ARN. Null when create\_prompt\_management = false. |
| <a name="output_prompt_bridge_environment_variables"></a> [prompt\_bridge\_environment\_variables](#output\_prompt\_bridge\_environment\_variables) | Environment variable map for application runtimes (for example AgentCore containers) to consume Bedrock prompt references. Null when create\_prompt\_bridge = false. |
| <a name="output_prompt_bridge_prompt_arn"></a> [prompt\_bridge\_prompt\_arn](#output\_prompt\_bridge\_prompt\_arn) | Resolved prompt ARN for bridge consumers. Null when create\_prompt\_bridge = false. |
| <a name="output_prompt_bridge_prompt_id"></a> [prompt\_bridge\_prompt\_id](#output\_prompt\_bridge\_prompt\_id) | Resolved prompt ID for bridge consumers. Null when create\_prompt\_bridge = false. |
| <a name="output_prompt_bridge_prompt_version"></a> [prompt\_bridge\_prompt\_version](#output\_prompt\_bridge\_prompt\_version) | Resolved prompt version for bridge consumers. Null when create\_prompt\_bridge = false. |
| <a name="output_prompt_id"></a> [prompt\_id](#output\_prompt\_id) | Prompt ID. Null when create\_prompt\_management = false. |
| <a name="output_prompt_name"></a> [prompt\_name](#output\_prompt\_name) | Prompt name. Null when create\_prompt\_management = false. |
| <a name="output_prompt_version"></a> [prompt\_version](#output\_prompt\_version) | Prompt version (DRAFT on create). Null when create\_prompt\_management = false. |
<!-- END_TF_DOCS -->