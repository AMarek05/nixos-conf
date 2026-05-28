# OpenClaw Container Configuration
#
# Deploys OpenClaw as a Podman container on the host.
# Uses SOPS-nix for secrets on the host, mounts decrypted files into the container.
# Workspace is bind-mounted from the host.
#
# Approach: systemd service with `podman run` directly — the idiomatic NixOS way.
#
# NOTE: Disables sandboxedExecs and tools to break the circular evaluation chain
# between tools-loader.nix (evaluates all tool files) -> sandboxedExecs.package -> openclaw-sandboxed-bins
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

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/library/debian:stable-slim";
      description = "Container image to use.";
    };
  };

  config = lib.mkIf cfg.container.enable {
    # Disable tool loading and sandboxed execs to break the circular eval chain.
    # The tools-loader.nix imports all tool/*.nix files at module eval time,
    # and those files reference sandboxedExecs.package which includes
    # openclaw-sandboxed-bins (a symlinkJoin). With these disabled, the eval
    # chain is broken and the container config evaluates without infinite recursion.
    services.openclaw = {
      enable = true;
      tools.enable = false;
      sandboxedExecs.enable = false;

      # Override the defaults with container-appropriate values
      bindAddress = "0.0.0.0";
    };


    virtualisation.podman = {
      enable = true;
    };

    # SOPS secret paths are declared in the host's services.openclaw block.
    # We reference them via config.sops.secrets in the env generator.

    # Ensure secrets directory exists
    systemd.tmpfiles.rules = [
      "d /run/secrets.d 0755 root root -"
    ];

    # Generate secrets env file from decrypted SOPS files
    systemd.services.openclaw-container-env = {
      description = "OpenClaw container secrets generator";
      wantedBy = [ "openclaw-container.service" ];
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";

        ExecStart = pkgs.writeShellScript "openclaw-container-gen-env" ''
          set -euo pipefail

          # Wait for sops-nix to decrypt secrets (up to 30s)
          for i in $(seq 1 60); do
            if [ -f "${config.sops.secrets."nim-api-key".path}" ]; then
              break
            fi
            sleep 0.5
          done

          # Write secret files and env file
          {
            if [ -f "${config.sops.secrets."nim-api-key".path}" ]; then
              cp "${config.sops.secrets."nim-api-key".path}" /run/secrets.d/NVIDIA_API_KEY
              echo "NVIDIA_API_KEY=$(<${config.sops.secrets."nim-api-key".path})"
            fi
            if [ -f "${config.sops.secrets."openrouter-api-key".path}" ]; then
              cp "${config.sops.secrets."openrouter-api-key".path}" /run/secrets.d/OPENROUTER_API_KEY
              echo "OPENROUTER_API_KEY=$(<${config.sops.secrets."openrouter-api-key".path})"
            fi
            if [ -f "${config.sops.secrets."minimax-api-key".path}" ]; then
              cp "${config.sops.secrets."minimax-api-key".path}" /run/secrets.d/MINIMAX_API_KEY
              echo "MINIMAX_API_KEY=$(<${config.sops.secrets."minimax-api-key".path})"
            fi
            if [ -f "${config.sops.secrets."gh-token".path}" ]; then
              cp "${config.sops.secrets."gh-token".path}" /run/secrets.d/GH_TOKEN
              echo "GH_TOKEN=$(<${config.sops.secrets."gh-token".path})"
            fi
            if [ -f "${config.sops.secrets."claw-bot-key".path}" ]; then
              cp "${config.sops.secrets."claw-bot-key".path}" /run/secrets.d/DISCORD_BOT_TOKEN
              echo "DISCORD_BOT_TOKEN=$(<${config.sops.secrets."claw-bot-key".path})"
            fi
            echo "OPENCLAW_LOAD_SHELL_ENV=0"
          } > /run/secrets.d/env

          chmod 600 /run/secrets.d/env
          chmod 600 /run/secrets.d/*
        '';
      };
    };

    # OpenClaw container as a systemd service with `podman run`
    systemd.services.openclaw-container = {
      description = "OpenClaw Podman Container";
      wantedBy = [ "multi-user.target" ];
      after = [
        "sops-nix.service"
        "openclaw-container-env.service"
        "podman.socket"
        "network-online.target"
      ];
      requires = [
        "openclaw-container-env.service"
        "podman.socket"
      ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "exec";
        Restart = "on-failure";
        RestartSec = "5s";
        User = "root";
        Group = "root";

        ExecStartPre = [
          # Remove any stale container
          (pkgs.writeShellScript "openclaw-net-setup" ''
            set -e
            ${pkgs.podman}/bin/podman rm --force openclaw 2>/dev/null || true
          '')
        ];

        ExecStart = lib.mkForce ''
          ${pkgs.podman}/bin/podman run \
            --rm \
            --name openclaw \
            --hostname openclaw \
            --publish 0.0.0.0:${toString cfg.container.webUiPort}:${toString cfg.port} \
            --volume /var/lib/openclaw:/var/lib/openclaw:rw \
            --volume /run/current-system:/run/current-system:ro \
            --volume /run/secrets.d:/run/secrets.d:ro \
            --env-file /run/secrets.d/env \
            --read-only \
            --tmpfs /tmp:size=64m,noexec \
            --cap-drop=all \
            --security-opt=no-new-privileges \
            --user 0:0 \
            ${cfg.container.image} \
            env PATH=/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
            OPENCLAW_LOAD_SHELL_ENV=0 \
            /run/current-system/sw/bin/openclaw gateway --verbose
        '';

        ExecStop = "${pkgs.podman}/bin/podman stop -t 10 openclaw";
        KillMode = "mixed";
        TimeoutStopSec = 30;
      };
    };
  };
}