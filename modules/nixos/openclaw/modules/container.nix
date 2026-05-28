# OpenClaw Container Configuration
#
# Deploys OpenClaw as a Podman rootless container on the host.
# Uses SOPS-nix for secrets on the host, mounts decrypted files into the container.
# Workspace is bind-mounted from the host.
#
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
  options.services.openclaw.container = {
    enable = lib.mkEnableOption "Deploy OpenClaw as a Podman container";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "10.20.30.20";
      description = "Static IP for the container on the Podman network.";
    };

    networkName = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "Name of the Podman bridge network.";
    };

    webUiPort = lib.mkOption {
      type = lib.types.port;
      default = 18790;
      description = "Host port mapped to the gateway inside the container.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openclaw";
      description = "Host path for OpenClaw data (workspace, .openclaw).";
    };

    user = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID to run the container process as.";
    };

    group = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "GID to run the container process as.";
    };
  };

  config = lib.mkIf cfg.container.enable {
    virtualisation.podman = {
      enable = true;
      enableHttp = true;
    };

    # Create custom bridge network
    virtualisation.podman.networks.${cfg.container.networkName} = {
      driver = "bridge";
      subnet = "${lib.head (lib.splitString "." cfg.container.ip)}.${
          lib.elemAt (lib.splitString "." cfg.container.ip) 1}.${
          lib.elemAt (lib.splitString "." cfg.container.ip) 2}.0/24";
      gateway = "${lib.head (lib.splitString "." cfg.container.ip)}.${
          lib.elemAt (lib.splitString "." cfg.container.ip) 1}.${
          lib.elemAt (lib.splitString "." cfg.container.ip) 2}.1";
    };

    # Podman container definition
    virtualisation.podman.containers = {
      openclaw = {
        image = "docker.io/library/alpine:3";
        autoStart = true;

        user = {
          uid = cfg.container.user;
          gid = cfg.container.group;
        };

        # Inject secrets as environment variables via secret files
        environment = {
          NVIDIA_API_KEY_FILE = "/run/secrets.d/NVIDIA_API_KEY";
          OPENROUTER_API_KEY_FILE = "/run/secrets.d/OPENROUTER_API_KEY";
          MINIMAX_API_KEY_FILE = "/run/secrets.d/MINIMAX_API_KEY";
          GH_TOKEN_FILE = "/run/secrets.d/GH_TOKEN";
          DISCORD_BOT_TOKEN_FILE = "/run/secrets.d/DISCORD_BOT_TOKEN";
          OPENCLAW_LOAD_SHELL_ENV = "0";
        };

        volumes = [
          "${cfg.container.dataDir}:/var/lib/openclaw:rw"
          "/run/secrets.d:/run/secrets.d:ro"
        ];

        portMappings = [
          {
            hostPort = cfg.container.webUiPort;
            containerPort = cfg.port;
            protocol = "tcp";
          }
        ];

        networks = [ cfg.container.networkName ];

        command = [
          "sh"
          "-c"
          ''
            # Read secret files and export as env vars
            for f in /run/secrets.d/*; do
              if [ -f "$f" ]; then
                name=$(basename "$f")
                export "$name=$(cat "$f")"
              fi
            done
            mkdir -p /var/lib/openclaw/workspace /var/lib/openclaw/.openclaw/agents/main/agent
            exec /nix/var/nix/profiles/system/bin/openclaw gateway --verbose
          ''
        ];
      };
    };
  };
}