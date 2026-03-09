provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source = "../../"

  name = "example-prompt-management"

  create_prompt_management = true
  prompt_management_config = {
    name            = "example-system-prompt"
    description     = "Prompt management example with multiple variants."
    default_variant = "default"

    variants = [
      {
        name          = "default"
        template_type = "TEXT"
        model_id      = "amazon.titan-text-express-v1"
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
        name          = "chat-default"
        template_type = "CHAT"
        model_id      = "amazon.titan-text-express-v1"
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