provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name                  = "example-bedrock"
  create_knowledge_base = true

  knowledge_base = {
    description = "Managed Bedrock knowledge base backed by S3 Vectors"
  }

  tags = {
    Environment = "dev"
    Example     = "complete"
    Terraform   = "true"
  }
}
