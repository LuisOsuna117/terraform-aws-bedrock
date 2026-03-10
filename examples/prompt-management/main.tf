provider "aws" {
  region = var.aws_region
}

module "bedrock" {
  source = "../../"

  name = var.module_name

  create_prompt_management = true
  prompt_management_config = {
    name            = var.prompt_name
    description     = var.prompt_description
    default_variant = var.default_variant
    tags            = var.tags

    variants = [
      {
        name          = var.default_variant
        template_type = "TEXT"
        model_id      = var.model_id
        metadata = {
          owner = "platform"
          tier  = "default"
        }
        text_template = {
          text            = "You are a helpful assistant for {{tenant}}."
          input_variables = ["tenant"]
        }
        inference_text = {
          max_tokens  = 512
          temperature = 0.2
          top_p       = 0.9
        }
      },
      {
        name          = var.chat_variant_name
        template_type = "CHAT"
        model_id      = var.model_id
        chat_template = {
          input_variables = ["tenant", "question"]
          system_prompts = [
            {
              text = "You are a secure assistant for {{tenant}}."
            }
          ]
          messages = [
            {
              role = "user"
              text = "{{question}}"
            }
          ]
        }
      }
    ]
  }

  create_prompt_bridge = true
  prompt_bridge_config = {}
}