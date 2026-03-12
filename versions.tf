terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.27"
    }
  }
}

# NOTE: This module does not configure a provider block.
# AWS provider configuration (region, credentials, default_tags) is the
# responsibility of the caller. See the README for a usage example.
