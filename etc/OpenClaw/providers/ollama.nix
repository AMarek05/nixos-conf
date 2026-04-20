{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
in
{
  config = lib.mkIf cfg.enable {
    services.openclaw.extraConfig = {
      models = {
        providers = {
          # Provider name (change this)
          ollama = {
            # Provider type - choose one:
            # - "anthropic:api" for Anthropic
            # - "openai:default" for OpenAI
            # - "openai-compatible" for most others
            # - "google:api" for Gemini
            # - "deepseek:api" for DeepSeek
            type = "openai-compatible";

            # Base URL (for openai-compatible providers)
            baseUrl = "https://localhost:11434/v1";

            # API Key - reference from secrets
            # The key should be in secrets/openclaw.yaml as: my_provider_api_key: xxx
            apiKey = {
              "ollama" = "local";
            };

            # Available models (for openai-compatible)
            models = [
              "qwopus-iq4xs"
            ];

            # Optional: Default parameters
            defaultParams = {
              temperature = 0.7;
              max_tokens = 22000;
            };
          };
        };

        # Uncomment to make this provider the default:
        default = "ollama/qwopus-iq4xs";
      };
    };

    # Add environment variable for API key
    services.openclaw.environment = {
      MY_PROVIDER_API_KEY = lib.mkDefault "";
    };
  };
}

# No API key needed for local Ollama
