{ config, lib, ... }:

let
  openclaw = config.services.openclaw;
  templates = config.sops.templates;
in
{
  config = lib.mkIf openclaw.enable {
    # 1. Define the raw secret
    sops.secrets."nim-api-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = openclaw.user;
    };

    sops.secrets."openrouter-api-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = openclaw.user;
    };

    sops.secrets."minimax-api-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = openclaw.user;
    };

    sops.secrets."gh-token" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = openclaw.user;
    };

    sops.secrets."claw-ssh-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;

      owner = openclaw.user;
      mode = "0400";
    };

    sops.secrets."claw-bot-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;

      owner = openclaw.user;
    };

    sops.templates."github-agent-env" = {
      owner = openclaw.user;
      group = openclaw.group;

      content = ''
        GH_TOKEN=${config.sops.placeholder."gh-token"}
      '';
    };

    # 2. Create an EnvironmentFile template
    # This creates a file at /run/secrets-render/openclaw-env
    sops.templates."openclaw-env" = {
      content = ''
        NVIDIA_API_KEY=${config.sops.placeholder."nim-api-key"}
        OPENROUTER_API_KEY=${config.sops.placeholder."openrouter-api-key"}
      '';
      owner = openclaw.user;
      group = openclaw.group;
    };

    # 3. Tell the service to wait for the secrets
    systemd.services.openclaw = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
