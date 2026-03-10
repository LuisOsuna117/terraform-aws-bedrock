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
| <a name="module_agent"></a> [agent](#module\_agent) | ./modules/agent | n/a |
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
| <a name="input_agent_config"></a> [agent\_config](#input\_agent\_config) | Configuration object for the agent module. Required when create\_agent = true. | <pre>object({<br/>    name                        = optional(string)<br/>    role_arn                    = string<br/>    foundation_model            = string<br/>    instruction                 = optional(string)<br/>    description                 = optional(string)<br/>    idle_session_ttl_in_seconds = optional(number, 600)<br/>    agent_collaboration         = optional(string, "DISABLED")<br/>    customer_encryption_key_arn = optional(string)<br/>    prepare_agent               = optional(bool, true)<br/>    skip_resource_in_use_check  = optional(bool, false)<br/>    region                      = optional(string)<br/>    tags                        = optional(map(string), {})<br/>    guardrail_id                = optional(string)<br/>    guardrail_version           = optional(string, "DRAFT")<br/><br/>    memory_configuration = optional(object({<br/>      enabled_memory_types = list(string)<br/>      storage_days         = optional(number)<br/>      max_recent_sessions  = optional(number)<br/>    }))<br/><br/>    action_groups = optional(map(object({<br/>      name                          = optional(string)<br/>      description                   = optional(string)<br/>      action_group_state            = optional(string, "ENABLED")<br/>      parent_action_group_signature = optional(string)<br/>      lambda_arn                    = optional(string)<br/>      custom_control                = optional(string)<br/>      api_schema_payload            = optional(string)<br/>      api_schema_s3_bucket          = optional(string)<br/>      api_schema_s3_key             = optional(string)<br/>      prepare_agent                 = optional(bool, true)<br/>      skip_resource_in_use_check    = optional(bool, true)<br/>      region                        = optional(string)<br/>      function_schema = optional(object({<br/>        functions = optional(list(object({<br/>          name        = string<br/>          description = optional(string)<br/>          parameters = optional(list(object({<br/>            name        = string<br/>            type        = string<br/>            description = optional(string)<br/>            required    = optional(bool)<br/>          })), [])<br/>        })), [])<br/>      }))<br/>    })), {})<br/><br/>    knowledge_base_associations = optional(map(object({<br/>      knowledge_base_id    = string<br/>      description          = string<br/>      knowledge_base_state = optional(string, "ENABLED")<br/>      region               = optional(string)<br/>    })), {})<br/><br/>    aliases = optional(map(object({<br/>      name                   = optional(string)<br/>      description            = optional(string)<br/>      agent_version          = optional(string)<br/>      provisioned_throughput = optional(string)<br/>      region                 = optional(string)<br/>      tags                   = optional(map(string), {})<br/>    })), {})<br/><br/>    collaborators = optional(map(object({<br/>      name                       = optional(string)<br/>      alias_arn                  = string<br/>      collaboration_instruction  = string<br/>      relay_conversation_history = optional(string)<br/>      prepare_agent              = optional(bool, true)<br/>      region                     = optional(string)<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_create_agent"></a> [create\_agent](#input\_create\_agent) | When true, creates a Bedrock agent and its child resources using modules/agent. | `bool` | `false` | no |
| <a name="input_create_guardrail"></a> [create\_guardrail](#input\_create\_guardrail) | When true, creates an Amazon Bedrock guardrail using modules/guardrail. | `bool` | `false` | no |
| <a name="input_create_knowledge_base"></a> [create\_knowledge\_base](#input\_create\_knowledge\_base) | When true, creates a Bedrock knowledge base using modules/knowledge\_base. | `bool` | `false` | no |
| <a name="input_create_prompt_management"></a> [create\_prompt\_management](#input\_create\_prompt\_management) | When true, creates a Bedrock prompt resource using modules/prompt\_management. | `bool` | `false` | no |
| <a name="input_embedding_model_arn"></a> [embedding\_model\_arn](#input\_embedding\_model\_arn) | ARN of the Bedrock embedding model. Required when knowledge\_base\_type = VECTOR. | `string` | `null` | no |
| <a name="input_guardrail_config"></a> [guardrail\_config](#input\_guardrail\_config) | Configuration object for the guardrail module. Required when create\_guardrail = true. | <pre>object({<br/>    name                      = optional(string)<br/>    blocked_input_messaging   = string<br/>    blocked_outputs_messaging = string<br/>    description               = optional(string)<br/>    kms_key_arn               = optional(string)<br/>    region                    = optional(string)<br/>    tags                      = optional(map(string), {})<br/>    content_policy_config = optional(object({<br/>      filters_config = optional(list(object({<br/>        input_action      = optional(string)<br/>        input_enabled     = optional(bool)<br/>        input_modalities  = optional(list(string))<br/>        input_strength    = optional(string)<br/>        output_action     = optional(string)<br/>        output_enabled    = optional(bool)<br/>        output_modalities = optional(list(string))<br/>        output_strength   = optional(string)<br/>        type              = optional(string)<br/>      })), [])<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    contextual_grounding_policy_config = optional(object({<br/>      filters_config = list(object({<br/>        threshold = number<br/>        type      = string<br/>      }))<br/>    }))<br/>    cross_region_config = optional(object({<br/>      guardrail_profile_identifier = string<br/>    }))<br/>    sensitive_information_policy_config = optional(object({<br/>      pii_entities_config = optional(list(object({<br/>        action         = string<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      regexes_config = optional(list(object({<br/>        action         = string<br/>        description    = optional(string)<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        name           = string<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        pattern        = string<br/>      })), [])<br/>    }))<br/>    topic_policy_config = optional(object({<br/>      topics_config = list(object({<br/>        definition = string<br/>        examples   = optional(list(string))<br/>        name       = string<br/>        type       = string<br/>      }))<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    word_policy_config = optional(object({<br/>      managed_word_lists_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      words_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        text           = string<br/>      })), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_kendra_index_arn"></a> [kendra\_index\_arn](#input\_kendra\_index\_arn) | Kendra index ARN. Required when knowledge\_base\_type = KENDRA. | `string` | `null` | no |
| <a name="input_knowledge_base_description"></a> [knowledge\_base\_description](#input\_knowledge\_base\_description) | Optional description for the knowledge base. | `string` | `null` | no |
| <a name="input_knowledge_base_name"></a> [knowledge\_base\_name](#input\_knowledge\_base\_name) | Explicit name for the knowledge base. Defaults to var.name when not set. | `string` | `null` | no |
| <a name="input_knowledge_base_region"></a> [knowledge\_base\_region](#input\_knowledge\_base\_region) | Optional region override for the knowledge base resource. | `string` | `null` | no |
| <a name="input_knowledge_base_role_arn"></a> [knowledge\_base\_role\_arn](#input\_knowledge\_base\_role\_arn) | IAM role ARN used by the knowledge base. Required when create\_knowledge\_base = true. | `string` | `null` | no |
| <a name="input_knowledge_base_tags"></a> [knowledge\_base\_tags](#input\_knowledge\_base\_tags) | Additional tags applied specifically to knowledge base resources. | `map(string)` | `{}` | no |
| <a name="input_knowledge_base_type"></a> [knowledge\_base\_type](#input\_knowledge\_base\_type) | Knowledge base type: VECTOR (default), KENDRA, or SQL. | `string` | `"VECTOR"` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used as a prefix for resources when per-module names are not explicitly set. | `string` | n/a | yes |
| <a name="input_opensearch_managed_cluster"></a> [opensearch\_managed\_cluster](#input\_opensearch\_managed\_cluster) | Existing OpenSearch Managed Cluster settings. Used when storage\_type = OPENSEARCH\_MANAGED\_CLUSTER. | <pre>object({<br/>    domain_arn        = string<br/>    domain_endpoint   = string<br/>    vector_index_name = string<br/>    field_metadata    = optional(string, "AMAZON_BEDROCK_METADATA")<br/>    field_text        = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")<br/>    field_vector      = optional(string, "bedrock-knowledge-base-default-vector")<br/>  })</pre> | `null` | no |
| <a name="input_opensearch_serverless"></a> [opensearch\_serverless](#input\_opensearch\_serverless) | OpenSearch Serverless collection settings. Auto-created when storage\_type = OPENSEARCH\_SERVERLESS. | <pre>object({<br/>    collection_name        = optional(string)<br/>    vector_index_name      = optional(string)<br/>    description            = optional(string)<br/>    kms_key_arn            = optional(string)<br/>    public_access          = optional(bool, true)<br/>    data_access_principals = optional(list(string), [])<br/>    field_metadata         = optional(string, "AMAZON_BEDROCK_METADATA")<br/>    field_text             = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")<br/>    field_vector           = optional(string, "bedrock-knowledge-base-default-vector")<br/>    tags                   = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_prompt_management_config"></a> [prompt\_management\_config](#input\_prompt\_management\_config) | Configuration object for the prompt management module. Required when create\_prompt\_management = true. | <pre>object({<br/>    tags = optional(map(string), {})<br/>    prompts = optional(map(object({<br/>      name                        = string<br/>      description                 = optional(string)<br/>      default_variant             = optional(string)<br/>      customer_encryption_key_arn = optional(string)<br/>      region                      = optional(string)<br/>      tags                        = optional(map(string), {})<br/>      variants = optional(list(object({<br/>        name                            = string<br/>        template_type                   = string<br/>        model_id                        = optional(string)<br/>        additional_model_request_fields = optional(map(any))<br/>        metadata                        = optional(map(string))<br/>        gen_ai_agent_identifier         = optional(string)<br/>        inference_text = optional(object({<br/>          max_tokens     = optional(number)<br/>          stop_sequences = optional(list(string))<br/>          temperature    = optional(number)<br/>          top_p          = optional(number)<br/>        }))<br/>        text_template = optional(object({<br/>          text             = string<br/>          input_variables  = optional(list(string), [])<br/>          cache_point_type = optional(string)<br/>        }))<br/>        chat_template = optional(object({<br/>          input_variables = optional(list(string), [])<br/>          messages = optional(list(object({<br/>            role             = string<br/>            text             = optional(string)<br/>            cache_point_type = optional(string)<br/>          })), [])<br/>          system_prompts = optional(list(object({<br/>            text             = optional(string)<br/>            cache_point_type = optional(string)<br/>          })), [])<br/>        }))<br/>      })), [])<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_rds"></a> [rds](#input\_rds) | Aurora PostgreSQL + pgvector settings. Auto-created when storage\_type = RDS. | <pre>object({<br/>    vpc_id                          = string<br/>    subnet_ids                      = list(string)<br/>    cluster_identifier              = optional(string)<br/>    engine_version                  = optional(string, "16.4")<br/>    database_name                   = optional(string, "bedrock_kb")<br/>    master_username                 = optional(string, "bedrock")<br/>    table_name                      = optional(string, "bedrock_integration.bedrock_kb")<br/>    min_capacity                    = optional(number, 0.5)<br/>    max_capacity                    = optional(number, 4.0)<br/>    skip_final_snapshot             = optional(bool, true)<br/>    allowed_cidr_blocks             = optional(list(string), [])<br/>    allowed_security_group_ids      = optional(list(string), [])<br/>    allowed_egress_cidr_blocks      = optional(list(string), [])<br/>    kms_key_id                      = optional(string)<br/>    backup_retention_period         = optional(number, 7)<br/>    deletion_protection             = optional(bool, true)<br/>    performance_insights_enabled    = optional(bool, true)<br/>    performance_insights_kms_key_id = optional(string)<br/>    field_metadata                  = optional(string, "metadata")<br/>    field_primary_key               = optional(string, "id")<br/>    field_text                      = optional(string, "chunks")<br/>    field_vector                    = optional(string, "embedding")<br/>    tags                            = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_redshift"></a> [redshift](#input\_redshift) | Redshift Serverless settings. Auto-created when knowledge\_base\_type = SQL. | <pre>object({<br/>    vpc_id                     = string<br/>    subnet_ids                 = list(string)<br/>    namespace_name             = optional(string)<br/>    workgroup_name             = optional(string)<br/>    database_name              = optional(string, "bedrock_kb")<br/>    admin_username             = optional(string, "admin")<br/>    base_capacity              = optional(number, 8)<br/>    publicly_accessible        = optional(bool, false)<br/>    allowed_cidr_blocks        = optional(list(string), [])<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_egress_cidr_blocks = optional(list(string), [])<br/>    tags                       = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_s3_vectors"></a> [s3\_vectors](#input\_s3\_vectors) | S3 Vectors bucket and index settings. Auto-created when storage\_type = S3\_VECTORS. | <pre>object({<br/>    vector_bucket_name = optional(string)<br/>    index_name         = optional(string)<br/>    data_type          = optional(string, "float32")<br/>    dimension          = number<br/>    distance_metric    = optional(string, "euclidean")<br/>    tags               = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Vector storage backend: S3\_VECTORS (default), OPENSEARCH\_SERVERLESS, OPENSEARCH\_MANAGED\_CLUSTER, or RDS. | `string` | `"S3_VECTORS"` | no |
| <a name="input_supplemental_s3_uri"></a> [supplemental\_s3\_uri](#input\_supplemental\_s3\_uri) | S3 URI for supplemental multimodal data storage. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto all resources managed by this module. | `map(string)` | `{}` | no |
| <a name="input_vector_embedding_data_type"></a> [vector\_embedding\_data\_type](#input\_vector\_embedding\_data\_type) | Embedding data type: FLOAT32 or BINARY. | `string` | `null` | no |
| <a name="input_vector_embedding_dimensions"></a> [vector\_embedding\_dimensions](#input\_vector\_embedding\_dimensions) | Optional dimensions override for the embedding model. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_aliases"></a> [agent\_aliases](#output\_agent\_aliases) | Map of alias key → alias attributes (agent\_alias\_id, agent\_alias\_arn). Empty map when create\_agent = false. |
| <a name="output_agent_arn"></a> [agent\_arn](#output\_agent\_arn) | Agent ARN. Null when create\_agent = false. |
| <a name="output_agent_id"></a> [agent\_id](#output\_agent\_id) | Agent ID. Null when create\_agent = false. |
| <a name="output_guardrail_arn"></a> [guardrail\_arn](#output\_guardrail\_arn) | Guardrail ARN. Null when create\_guardrail = false. |
| <a name="output_guardrail_id"></a> [guardrail\_id](#output\_guardrail\_id) | Guardrail ID. Null when create\_guardrail = false. |
| <a name="output_guardrail_status"></a> [guardrail\_status](#output\_guardrail\_status) | Guardrail status. Null when create\_guardrail = false. |
| <a name="output_guardrail_version"></a> [guardrail\_version](#output\_guardrail\_version) | Guardrail version. Null when create\_guardrail = false. |
| <a name="output_knowledge_base_arn"></a> [knowledge\_base\_arn](#output\_knowledge\_base\_arn) | Knowledge base ARN. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_id"></a> [knowledge\_base\_id](#output\_knowledge\_base\_id) | Knowledge base ID. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_name"></a> [knowledge\_base\_name](#output\_knowledge\_base\_name) | Knowledge base name. Null when create\_knowledge\_base = false. |
| <a name="output_prompts"></a> [prompts](#output\_prompts) | Map of logical key → prompt attributes (id, arn, name, version, created\_at, updated\_at). Empty map when create\_prompt\_management = false. |
| <a name="output_rds_cluster_arn"></a> [rds\_cluster\_arn](#output\_rds\_cluster\_arn) | Aurora cluster ARN. Null when storage\_type != RDS. |
| <a name="output_rds_cluster_endpoint"></a> [rds\_cluster\_endpoint](#output\_rds\_cluster\_endpoint) | Aurora writer endpoint. Null when storage\_type != RDS. |
| <a name="output_rds_secret_arn"></a> [rds\_secret\_arn](#output\_rds\_secret\_arn) | ARN of the Secrets Manager secret holding the Aurora master credentials. Null when storage\_type != RDS. |
| <a name="output_redshift_admin_secret_arn"></a> [redshift\_admin\_secret\_arn](#output\_redshift\_admin\_secret\_arn) | ARN of the Secrets Manager secret holding the Redshift admin credentials. Null when knowledge\_base\_type != SQL. |
| <a name="output_redshift_namespace_arn"></a> [redshift\_namespace\_arn](#output\_redshift\_namespace\_arn) | Redshift Serverless namespace ARN. Null when knowledge\_base\_type != SQL. |
| <a name="output_redshift_workgroup_endpoint"></a> [redshift\_workgroup\_endpoint](#output\_redshift\_workgroup\_endpoint) | Redshift Serverless workgroup endpoint address. Null when knowledge\_base\_type != SQL. |
<!-- END_TF_DOCS -->