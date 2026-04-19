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
    # NVIDIA NIM provider configuration
    services.openclaw.extraConfig = {

      # Handle the default model placement (OpenClaw's new schema location)
      agents = lib.optionalAttrs (cfg.defaultProvider == "nvidia") {
        defaults = {
          model = {
            primary = cfg.defaultModel;
          };
        };
      };

      models = {
        providers = {
          nvidia = {
            api = "openai-completions";
            baseUrl = "https://integrate.api.nvidia.com/v1";

            models = [
              {
                id = "moonshotai/kimi-k2-5";
                name = "Kimi K2.5";
              }
              {
                id = "z-ai/glm5";
                name = "GLM 5";
              }
              {
                id = "z-ai/glm-5.1";
                name = "GLM 5.1";
              }

            ];
          };
        };
      };
    };

    # Ensure NVIDIA_API_KEY is expected
    services.openclaw.environment = {
      NVIDIA_API_KEY = lib.mkDefault ""; # Will be set by SOPS
    };

    # Systemd service environment for NVIDIA
    systemd.services.openclaw.environment = {
      NVIDIA_API_KEY = lib.mkDefault "";
    };
  };
}
