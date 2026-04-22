{ config, lib, ... }:

let
  cfg = config.services.openclaw;
  templates = config.sops.templates;
in
{
  config = lib.mkIf cfg.enable {
    # 1. Define the raw secret
    sops.secrets."nim-api-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = cfg.user;
    };

    sops.secrets."openrouter-api-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = cfg.user;
    };

    sops.secrets."gh-token" = {
      sopsFile = ../../../secrets/openclaw.yaml;
      owner = cfg.user;
    };

    sops.secrets."claw-ssh-key" = {
      sopsFile = ../../../secrets/openclaw.yaml;

      owner = cfg.user;
      mode = "0400";
    };

    sops.templates."github-agent-env" = {
      owner = cfg.user;
      group = cfg.group;

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
        GIT_SSH_COMMAND=ssh -F /dev/null -i ${
          config.sops.secrets."claw-ssh-key".path
        } -o StrictHostKeyChecking=accept-new
      '';
      owner = cfg.user;
      group = cfg.group;
    };

    # 3. Tell the service to wait for the secrets
    systemd.services.openclaw = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];

      serviceConfig.EnvironmentFile = [
        templates."openclaw-env".path
        templates."github-agent-env".path
      ];
    };
  };
}
