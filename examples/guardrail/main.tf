provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name             = "example-guardrail"
  create_guardrail = true

  guardrail = {
    create_version = true
    description    = "Example Bedrock guardrail"

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

    word_policy_config = {
      managed_word_lists_config = [
        {
          type = "PROFANITY"
        }
      ]
    }
  }

  tags = {
    Example = "guardrail"
  }
}
