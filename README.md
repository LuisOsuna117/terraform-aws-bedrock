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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.27 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_guardrail"></a> [guardrail](#module\_guardrail) | ./modules/guardrail | n/a |
| <a name="module_knowledge_base"></a> [knowledge\_base](#module\_knowledge\_base) | ./modules/knowledge_base | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | Top-level module enable flag. | `bool` | `true` | no |
| <a name="input_create_guardrail"></a> [create\_guardrail](#input\_create\_guardrail) | When true, create the Bedrock guardrail submodule. | `bool` | `false` | no |
| <a name="input_create_knowledge_base"></a> [create\_knowledge\_base](#input\_create\_knowledge\_base) | When true, create the Bedrock knowledge base submodule. | `bool` | `false` | no |
| <a name="input_guardrail"></a> [guardrail](#input\_guardrail) | Guardrail configuration forwarded to modules/guardrail. | <pre>object({<br/>    name                      = optional(string)<br/>    create_version            = optional(bool, false)<br/>    blocked_input_messaging   = optional(string)<br/>    blocked_outputs_messaging = optional(string)<br/>    description               = optional(string)<br/>    kms_key_arn               = optional(string)<br/>    content_policy_config = optional(object({<br/>      filters_config = optional(list(object({<br/>        input_action      = optional(string)<br/>        input_enabled     = optional(bool)<br/>        input_modalities  = optional(list(string))<br/>        input_strength    = optional(string)<br/>        output_action     = optional(string)<br/>        output_enabled    = optional(bool)<br/>        output_modalities = optional(list(string))<br/>        output_strength   = optional(string)<br/>        type              = optional(string)<br/>      })), [])<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    contextual_grounding_policy_config = optional(object({<br/>      filters_config = list(object({<br/>        threshold = number<br/>        type      = string<br/>      }))<br/>    }))<br/>    cross_region_config = optional(object({<br/>      guardrail_profile_identifier = string<br/>    }))<br/>    sensitive_information_policy_config = optional(object({<br/>      pii_entities_config = optional(list(object({<br/>        action         = string<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      regexes_config = optional(list(object({<br/>        action         = string<br/>        description    = optional(string)<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        name           = string<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        pattern        = string<br/>      })), [])<br/>    }))<br/>    topic_policy_config = optional(object({<br/>      topics_config = list(object({<br/>        definition = string<br/>        examples   = optional(list(string))<br/>        name       = string<br/>        type       = string<br/>      }))<br/>      tier_config = optional(object({<br/>        tier_name = string<br/>      }))<br/>    }))<br/>    word_policy_config = optional(object({<br/>      managed_word_lists_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        type           = string<br/>      })), [])<br/>      words_config = optional(list(object({<br/>        input_action   = optional(string)<br/>        input_enabled  = optional(bool)<br/>        output_action  = optional(string)<br/>        output_enabled = optional(bool)<br/>        text           = string<br/>      })), [])<br/>    }))<br/>    version_description  = optional(string)<br/>    version_skip_destroy = optional(bool, false)<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }), {})<br/>    version_timeouts = optional(object({<br/>      create = optional(string)<br/>      delete = optional(string)<br/>    }), {})<br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_knowledge_base"></a> [knowledge\_base](#input\_knowledge\_base) | Knowledge base configuration forwarded to modules/knowledge\_base. | <pre>object({<br/>    name                             = optional(string)<br/>    description                      = optional(string)<br/>    create_role                      = optional(bool, true)<br/>    create_vector_bucket             = optional(bool, true)<br/>    create_vector_index              = optional(bool, true)<br/>    role_arn                         = optional(string)<br/>    embedding_model_arn              = optional(string)<br/>    supplemental_data_storage_s3_uri = optional(string)<br/>    iam_role = optional(object({<br/>      name                 = optional(string)<br/>      description          = optional(string)<br/>      path                 = optional(string, "/")<br/>      permissions_boundary = optional(string)<br/>      max_session_duration = optional(number, 3600)<br/>      tags                 = optional(map(string), {})<br/>    }), {})<br/>    iam_role_additional_policy_documents = optional(list(string), [])<br/>    s3_vectors = optional(object({<br/>      vector_bucket_arn  = optional(string)<br/>      vector_bucket_name = optional(string)<br/>      index_arn          = optional(string)<br/>      index_name         = optional(string)<br/>      dimension          = optional(number, 1024)<br/>      distance_metric    = optional(string, "cosine")<br/>      data_type          = optional(string, "float32")<br/>      force_destroy      = optional(bool, false)<br/>      non_filterable_metadata_keys = optional(list(string), [<br/>        "AMAZON_BEDROCK_TEXT",<br/>        "AMAZON_BEDROCK_METADATA",<br/>      ])<br/>      bucket_encryption = optional(object({<br/>        sse_type    = optional(string, "AES256")<br/>        kms_key_arn = optional(string)<br/>      }))<br/>      index_encryption = optional(object({<br/>        sse_type    = optional(string, "AES256")<br/>        kms_key_arn = optional(string)<br/>      }))<br/>      tags = optional(map(string), {})<br/>    }), {})<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }), {})<br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used by child modules when a feature-specific name override is not set. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto all managed resources. Feature-specific tag maps are merged on top. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guardrail_arn"></a> [guardrail\_arn](#output\_guardrail\_arn) | Guardrail ARN. Null when create\_guardrail = false. |
| <a name="output_guardrail_created_at"></a> [guardrail\_created\_at](#output\_guardrail\_created\_at) | Unix epoch timestamp in seconds for when the guardrail was created. Null when create\_guardrail = false. |
| <a name="output_guardrail_draft_version"></a> [guardrail\_draft\_version](#output\_guardrail\_draft\_version) | Draft version reported by aws\_bedrock\_guardrail. Null when create\_guardrail = false. |
| <a name="output_guardrail_id"></a> [guardrail\_id](#output\_guardrail\_id) | Guardrail ID. Null when create\_guardrail = false. |
| <a name="output_guardrail_published_version"></a> [guardrail\_published\_version](#output\_guardrail\_published\_version) | Published version created by aws\_bedrock\_guardrail\_version. Null when no version is created. |
| <a name="output_guardrail_status"></a> [guardrail\_status](#output\_guardrail\_status) | Guardrail status. Null when create\_guardrail = false. |
| <a name="output_knowledge_base_arn"></a> [knowledge\_base\_arn](#output\_knowledge\_base\_arn) | ARN of the Bedrock knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_distance_metric"></a> [knowledge\_base\_distance\_metric](#output\_knowledge\_base\_distance\_metric) | Distance metric configured for the knowledge base S3 Vectors index. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_embedding_model_arn"></a> [knowledge\_base\_embedding\_model\_arn](#output\_knowledge\_base\_embedding\_model\_arn) | Embedding model ARN used by the Bedrock knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_id"></a> [knowledge\_base\_id](#output\_knowledge\_base\_id) | ID of the Bedrock knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_managed_role_arn"></a> [knowledge\_base\_managed\_role\_arn](#output\_knowledge\_base\_managed\_role\_arn) | ARN of the managed IAM role created by the knowledge base submodule. Null when no managed role is created. |
| <a name="output_knowledge_base_managed_role_name"></a> [knowledge\_base\_managed\_role\_name](#output\_knowledge\_base\_managed\_role\_name) | Name of the managed IAM role created by the knowledge base submodule. Null when no managed role is created. |
| <a name="output_knowledge_base_name"></a> [knowledge\_base\_name](#output\_knowledge\_base\_name) | Name of the Bedrock knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_role_arn"></a> [knowledge\_base\_role\_arn](#output\_knowledge\_base\_role\_arn) | Role ARN used by the Bedrock knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_vector_bucket_arn"></a> [knowledge\_base\_vector\_bucket\_arn](#output\_knowledge\_base\_vector\_bucket\_arn) | ARN of the S3 Vectors bucket backing the knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_vector_bucket_name"></a> [knowledge\_base\_vector\_bucket\_name](#output\_knowledge\_base\_vector\_bucket\_name) | Name of the S3 Vectors bucket backing the knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_vector_dimension"></a> [knowledge\_base\_vector\_dimension](#output\_knowledge\_base\_vector\_dimension) | Vector dimension configured for the knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_vector_index_arn"></a> [knowledge\_base\_vector\_index\_arn](#output\_knowledge\_base\_vector\_index\_arn) | ARN of the S3 Vectors index backing the knowledge base. Null when create\_knowledge\_base = false. |
| <a name="output_knowledge_base_vector_index_name"></a> [knowledge\_base\_vector\_index\_name](#output\_knowledge\_base\_vector\_index\_name) | Name of the S3 Vectors index backing the knowledge base. Null when create\_knowledge\_base = false. |
<!-- END_TF_DOCS -->
