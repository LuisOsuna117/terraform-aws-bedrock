resource "aws_bedrockagent_prompt" "this" {
  for_each = var.prompts

  name                        = each.value.name
  description                 = try(each.value.description, null)
  default_variant             = try(each.value.default_variant, null)
  customer_encryption_key_arn = try(each.value.customer_encryption_key_arn, null)
  region                      = try(each.value.region, null)
  tags                        = merge(var.tags, try(each.value.tags, {}))

  dynamic "variant" {
    for_each = try(each.value.variants, [])
    content {
      name                            = variant.value.name
      model_id                        = try(variant.value.model_id, null)
      template_type                   = variant.value.template_type
      additional_model_request_fields = try(variant.value.additional_model_request_fields, null)

      dynamic "metadata" {
        for_each = try(variant.value.metadata, {})
        content {
          key   = metadata.key
          value = metadata.value
        }
      }

      dynamic "inference_configuration" {
        for_each = try(variant.value.inference_text, null) != null ? [variant.value.inference_text] : []
        content {
          text {
            max_tokens     = try(inference_configuration.value.max_tokens, null)
            stop_sequences = try(inference_configuration.value.stop_sequences, null)
            temperature    = try(inference_configuration.value.temperature, null)
            top_p          = try(inference_configuration.value.top_p, null)
          }
        }
      }

      dynamic "gen_ai_resource" {
        for_each = try(variant.value.gen_ai_agent_identifier, null) != null ? [variant.value.gen_ai_agent_identifier] : []
        content {
          agent {
            agent_identifier = gen_ai_resource.value
          }
        }
      }

      dynamic "template_configuration" {
        for_each = [1]
        content {
          dynamic "text" {
            for_each = variant.value.template_type == "TEXT" ? [variant.value.text_template] : []
            content {
              text = text.value.text

              dynamic "input_variable" {
                for_each = try(text.value.input_variables, [])
                content {
                  name = input_variable.value
                }
              }

              dynamic "cache_point" {
                for_each = try(text.value.cache_point_type, null) != null ? [text.value.cache_point_type] : []
                content {
                  type = cache_point.value
                }
              }
            }
          }

          dynamic "chat" {
            for_each = variant.value.template_type == "CHAT" ? [variant.value.chat_template] : []
            content {
              dynamic "input_variable" {
                for_each = try(chat.value.input_variables, [])
                content {
                  name = input_variable.value
                }
              }

              dynamic "message" {
                for_each = try(chat.value.messages, [])
                content {
                  role = message.value.role

                  content {
                    text = try(message.value.text, null)

                    dynamic "cache_point" {
                      for_each = try(message.value.cache_point_type, null) != null ? [message.value.cache_point_type] : []
                      content {
                        type = cache_point.value
                      }
                    }
                  }
                }
              }

              dynamic "system" {
                for_each = try(chat.value.system_prompts, [])
                content {
                  text = try(system.value.text, null)

                  dynamic "cache_point" {
                    for_each = try(system.value.cache_point_type, null) != null ? [system.value.cache_point_type] : []
                    content {
                      type = cache_point.value
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
