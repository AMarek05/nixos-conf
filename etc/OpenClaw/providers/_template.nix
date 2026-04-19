# OpenClaw Provider Template
#
# Use this template to add new AI providers to OpenClaw.
# Copy this file and modify the sections below.
#
# Provider types:
#   - anthropic:api    - Anthropic Claude models
#   - openai:default   - OpenAI GPT models
#   - openai-compatible - Any OpenAI-compatible API (most providers)
#   - google:api       - Google Gemini models
#   - deepseek:api     - DeepSeek models
#   - ollama           - Local Ollama models
#
# To add a new provider:
# 1. Copy this template: cp _template.nix my-provider.nix
# 2. Modify the provider configuration below
# 3. Add required secrets to your secrets/openclaw.yaml
# 4. Rebuild your NixOS system

{ config, lib, pkgs, ... }:

let
  cfg = config.services.openclaw;
in {
  config = lib.mkIf cfg.enable {
    services.openclaw.extraConfig = {
      models = {
        providers = {
          # Provider name (change this)
          my-provider = {
            # Provider type - choose one:
            # - "anthropic:api" for Anthropic
            # - "openai:default" for OpenAI
            # - "openai-compatible" for most others
            # - "google:api" for Gemini
            # - "deepseek:api" for DeepSeek
            type = "openai-compatible";
            
            # Base URL (for openai-compatible providers)
            baseUrl = "https://api.example.com/v1";
            
            # API Key - reference from secrets
            # The key should be in secrets/openclaw.yaml as: my_provider_api_key: xxx
            apiKey = { "$ref" = "env.MY_PROVIDER_API_KEY"; };
            
            # Available models (for openai-compatible)
            models = [
              "model-1"
              "model-2"
            ];
            
            # Optional: Default parameters
            defaultParams = {
              temperature = 0.7;
              max_tokens = 4096;
            };
          };
        };
        
        # Uncomment to make this provider the default:
        # default = "my-provider/model-1";
      };
    };
    
    # Add environment variable for API key
    services.openclaw.environment = {
      MY_PROVIDER_API_KEY = lib.mkDefault "";
    };
  };
}

# ============================================================================
# EXAMPLE PROVIDER CONFIGURATIONS
# ============================================================================

# --- Anthropic Claude ---
# {
#   services.openclaw.extraConfig.models.providers.anthropic = {
#     type = "anthropic:api";
#     apiKey = { "$ref" = "env.ANTHROPIC_API_KEY"; };
#   };
# }
# Add to secrets/openclaw.yaml:
#   anthropic_api_key: sk-ant-xxx

# --- OpenAI ---
# {
#   services.openclaw.extraConfig.models.providers.openai = {
#     type = "openai:default";
#     apiKey = { "$ref" = "env.OPENAI_API_KEY"; };
#   };
# }
# Add to secrets/openclaw.yaml:
#   openai_api_key: sk-xxx

# --- Google Gemini ---
# {
#   services.openclaw.extraConfig.models.providers.google = {
#     type = "google:api";
#     apiKey = { "$ref" = "env.GOOGLE_API_KEY"; };
#   };
# }
# Add to secrets/openclaw.yaml:
#   google_api_key: AIzaxxx

# --- DeepSeek ---
# {
#   services.openclaw.extraConfig.models.providers.deepseek = {
#     type = "deepseek:api";
#     apiKey = { "$ref" = "env.DEEPSEEK_API_KEY"; };
#   };
# }
# Add to secrets/openclaw.yaml:
#   deepseek_api_key: sk-xxx

# --- OpenRouter ---
# {
#   services.openclaw.extraConfig.models.providers.openrouter = {
#     type = "openai-compatible";
#     baseUrl = "https://openrouter.ai/api/v1";
#     apiKey = { "$ref" = "env.OPENROUTER_API_KEY"; };
#     models = [
#       "anthropic/claude-sonnet-4"
#       "openai/gpt-4o"
#     ];
#   };
# }
# Add to secrets/openclaw.yaml:
#   openrouter_api_key: sk-or-xxx

# --- Ollama (Local) ---
# {
#   services.openclaw.extraConfig.models.providers.ollama = {
#     type = "ollama";
#     baseUrl = "http://localhost:11434";
#     models = [
#       "llama3.2"
#       "codellama"
#     ];
#   };
# }
# No API key needed for local Ollama
