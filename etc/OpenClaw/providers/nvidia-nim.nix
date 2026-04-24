{
  lib,
  ...
}:

{
  # NVIDIA NIM provider configuration
  services.openclaw.extraConfig = {
    models = {
      mode = "merge";
      providers = {
        nvidia-nim = {
          api = "openai-completions";

          baseUrl = "https://integrate.api.nvidia.com/v1";
          models = [
            {
              id = "minimaxai/minimax-m2.7";
              name = "Minimax M 2.7";
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              contextWindow = 128000;
            }
            {
              id = "z-ai/glm-5.1";
              name = "GLM 5.1";
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              contextWindow = 200000;
            }
          ];
        };
      };
    };

    plugins.entries.nvidia.enabled = false;
  };

  # Ensure NVIDIA_API_KEY is expected
  services.openclaw.environment = {
    NVIDIA_API_KEY = lib.mkDefault ""; # Will be set by SOPS
  };

  # Systemd service environment for NVIDIA
  systemd.services.openclaw.environment = {
    NVIDIA_API_KEY = lib.mkDefault "";
  };
}
