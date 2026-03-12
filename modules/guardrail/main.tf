locals {
  resolved_blocked_input_messaging   = coalesce(var.blocked_input_messaging, "This input was blocked by the guardrail.")
  resolved_blocked_outputs_messaging = coalesce(var.blocked_outputs_messaging, "This response was blocked by the guardrail.")
  resolved_guardrail_arn             = var.create ? aws_bedrock_guardrail.this[0].guardrail_arn : var.guardrail_arn

  guardrail_timeouts_configured = length(compact([
    try(var.timeouts.create, null),
    try(var.timeouts.update, null),
    try(var.timeouts.delete, null),
  ])) > 0

  version_timeouts_configured = length(compact([
    try(var.version_timeouts.create, null),
    try(var.version_timeouts.delete, null),
  ])) > 0
}

resource "terraform_data" "validation" {
  input = null

  lifecycle {
    precondition {
      condition     = !var.create || try(length(trimspace(var.name)) > 0, false)
      error_message = "Set name when create = true."
    }

    precondition {
      condition     = !var.create_version || var.create || var.guardrail_arn != null
      error_message = "Set guardrail_arn or leave create = true when create_version = true."
    }
  }
}

resource "aws_bedrock_guardrail" "this" {
  count = var.create ? 1 : 0

  name                      = var.name
  blocked_input_messaging   = local.resolved_blocked_input_messaging
  blocked_outputs_messaging = local.resolved_blocked_outputs_messaging
  description               = var.description
  kms_key_arn               = var.kms_key_arn
  tags                      = var.tags

  dynamic "content_policy_config" {
    for_each = var.content_policy_config == null ? [] : [var.content_policy_config]

    content {
      dynamic "filters_config" {
        for_each = try(content_policy_config.value.filters_config, [])

        content {
          input_action      = try(filters_config.value.input_action, null)
          input_enabled     = try(filters_config.value.input_enabled, null)
          input_modalities  = try(filters_config.value.input_modalities, null)
          input_strength    = try(filters_config.value.input_strength, null)
          output_action     = try(filters_config.value.output_action, null)
          output_enabled    = try(filters_config.value.output_enabled, null)
          output_modalities = try(filters_config.value.output_modalities, null)
          output_strength   = try(filters_config.value.output_strength, null)
          type              = try(filters_config.value.type, null)
        }
      }

      dynamic "tier_config" {
        for_each = try(content_policy_config.value.tier_config, null) == null ? [] : [content_policy_config.value.tier_config]

        content {
          tier_name = tier_config.value.tier_name
        }
      }
    }
  }

  dynamic "contextual_grounding_policy_config" {
    for_each = var.contextual_grounding_policy_config == null ? [] : [var.contextual_grounding_policy_config]

    content {
      dynamic "filters_config" {
        for_each = contextual_grounding_policy_config.value.filters_config

        content {
          threshold = filters_config.value.threshold
          type      = filters_config.value.type
        }
      }
    }
  }

  dynamic "cross_region_config" {
    for_each = var.cross_region_config == null ? [] : [var.cross_region_config]

    content {
      guardrail_profile_identifier = cross_region_config.value.guardrail_profile_identifier
    }
  }

  dynamic "sensitive_information_policy_config" {
    for_each = var.sensitive_information_policy_config == null ? [] : [var.sensitive_information_policy_config]

    content {
      dynamic "pii_entities_config" {
        for_each = try(sensitive_information_policy_config.value.pii_entities_config, [])

        content {
          action         = pii_entities_config.value.action
          input_action   = try(pii_entities_config.value.input_action, null)
          input_enabled  = try(pii_entities_config.value.input_enabled, null)
          output_action  = try(pii_entities_config.value.output_action, null)
          output_enabled = try(pii_entities_config.value.output_enabled, null)
          type           = pii_entities_config.value.type
        }
      }

      dynamic "regexes_config" {
        for_each = try(sensitive_information_policy_config.value.regexes_config, [])

        content {
          action         = regexes_config.value.action
          description    = try(regexes_config.value.description, null)
          input_action   = try(regexes_config.value.input_action, null)
          input_enabled  = try(regexes_config.value.input_enabled, null)
          name           = regexes_config.value.name
          output_action  = try(regexes_config.value.output_action, null)
          output_enabled = try(regexes_config.value.output_enabled, null)
          pattern        = regexes_config.value.pattern
        }
      }
    }
  }

  dynamic "topic_policy_config" {
    for_each = var.topic_policy_config == null ? [] : [var.topic_policy_config]

    content {
      dynamic "topics_config" {
        for_each = topic_policy_config.value.topics_config

        content {
          definition = topics_config.value.definition
          examples   = try(topics_config.value.examples, null)
          name       = topics_config.value.name
          type       = topics_config.value.type
        }
      }

      dynamic "tier_config" {
        for_each = try(topic_policy_config.value.tier_config, null) == null ? [] : [topic_policy_config.value.tier_config]

        content {
          tier_name = tier_config.value.tier_name
        }
      }
    }
  }

  dynamic "word_policy_config" {
    for_each = var.word_policy_config == null ? [] : [var.word_policy_config]

    content {
      dynamic "managed_word_lists_config" {
        for_each = try(word_policy_config.value.managed_word_lists_config, [])

        content {
          input_action   = try(managed_word_lists_config.value.input_action, null)
          input_enabled  = try(managed_word_lists_config.value.input_enabled, null)
          output_action  = try(managed_word_lists_config.value.output_action, null)
          output_enabled = try(managed_word_lists_config.value.output_enabled, null)
          type           = managed_word_lists_config.value.type
        }
      }

      dynamic "words_config" {
        for_each = try(word_policy_config.value.words_config, [])

        content {
          input_action   = try(words_config.value.input_action, null)
          input_enabled  = try(words_config.value.input_enabled, null)
          output_action  = try(words_config.value.output_action, null)
          output_enabled = try(words_config.value.output_enabled, null)
          text           = words_config.value.text
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = local.guardrail_timeouts_configured ? [var.timeouts] : []

    content {
      create = try(timeouts.value.create, null)
      delete = try(timeouts.value.delete, null)
      update = try(timeouts.value.update, null)
    }
  }

  depends_on = [terraform_data.validation]
}

resource "aws_bedrock_guardrail_version" "this" {
  count = var.create_version ? 1 : 0

  guardrail_arn = local.resolved_guardrail_arn
  description   = var.version_description
  skip_destroy  = var.version_skip_destroy

  dynamic "timeouts" {
    for_each = local.version_timeouts_configured ? [var.version_timeouts] : []

    content {
      create = try(timeouts.value.create, null)
      delete = try(timeouts.value.delete, null)
    }
  }

  depends_on = [terraform_data.validation]
}
