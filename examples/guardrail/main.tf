provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_guardrail = true
  guardrail_config = {
    name                      = var.guardrail_name
    blocked_input_messaging   = var.blocked_input_messaging
    blocked_outputs_messaging = var.blocked_outputs_messaging
    description               = var.guardrail_description
    tags                      = var.tags

    content_policy_config = {
      filters_config = [
        {
          type            = "HATE"
          input_strength  = "MEDIUM"
          output_strength = "MEDIUM"
        },
        {
          type            = "PROMPT_ATTACK"
          input_strength  = "HIGH"
          output_strength = "HIGH"
        }
      ]
      tier_config = {
        tier_name = "STANDARD"
      }
    }

    sensitive_information_policy_config = {
      pii_entities_config = [
        {
          action         = "BLOCK"
          input_action   = "BLOCK"
          output_action  = "ANONYMIZE"
          input_enabled  = true
          output_enabled = true
          type           = "NAME"
        }
      ]
      regexes_config = [
        {
          action         = "BLOCK"
          input_action   = "BLOCK"
          output_action  = "BLOCK"
          input_enabled  = true
          output_enabled = false
          name           = "ssn_regex"
          description    = "Detects US social security number format."
          pattern        = "^\\d{3}-\\d{2}-\\d{4}$"
        }
      ]
    }

    topic_policy_config = {
      topics_config = [
        {
          name       = "investment_topic"
          type       = "DENY"
          definition = "Investment advice refers to inquiries or recommendations regarding allocation of funds to generate returns."
          examples   = ["Where should I invest my money?"]
        }
      ]
      tier_config = {
        tier_name = "CLASSIC"
      }
    }

    word_policy_config = {
      managed_word_lists_config = [
        {
          type = "PROFANITY"
        }
      ]
      words_config = [
        {
          text = "HATE"
        }
      ]
    }
  }
}
