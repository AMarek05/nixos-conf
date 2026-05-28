# modules/nixos/openclaw/podman.nix
# Rootless Podman containerization for OpenClaw on NixOS
#
# Activate by setting `services.openclaw-podman.enable = true` on the target host.
# No openclaw bare-systemd service should be active at the same time.
#
# State is kept on the host via bind mounts — container rebuilds are stateless.

{ lib, config, pkgs, ... }:

let
  inherit (pkgs.lib) optionalString optionals concatStringsSep mkIf mkDefault getBin;
  cfg = config.services.openclaw-podman;
  pkgName = p: p.pname or (pkgs.lib.getName p);

  # Build the podman run arguments as a list, then join them
  podmanArgs = [
    (getBin pkgs.podman + "/bin/podman")
    "run"
    "--replace"
    "--name" cfg.containerName
    "--userns=keep-id"
    "--publish" "${cfg.bindAddress}:${toString cfg.port}:18789"
    "--publish" "${cfg.bindAddress}:${toString cfg.bridgePort}:18790"
    "--volume" "${cfg.stateDir}:/home/node/.openclaw:rw"
    "--env" "OPENCLAW_GATEWAY_BIND=${cfg.gatewayBind}"
    "--env" "DEBUG=${if cfg.debug then "1" else "0"}"
  ] ++ optionals (cfg.extraAPTPackages != [ ])
      ["--env" "OPENCLAW_IMAGE_APT_PACKAGES=${concatStringsSep "," cfg.extraAPTPackages}"]
  ++ (if cfg.debug
      then ["--timeout=300"]
      else ["--memory=4G" "--timeout=60"])
  ++ [ cfg.image ];

  runLine = concatStringsSep " " podmanArgs;

in
{

  options.services.openclaw-podman = {
    enable = lib.mkEnableOption ''
      OpenClaw via rootless Podman container.

      **Prerequisites:**
      - `virtualisation.podman.requiredUsers` includes the target user
      - `subuid`/`subgid` ranges configured for the target user
      - Systemd lingering enabled for boot-persistent auto-start:

          sudo loginctl enable-linger "${cfg.user}"

      **First-time state setup** (on the host before starting):

          mkdir -p ~/.openclaw
          cp /path/to/openclaw.json   ~/.openclaw/
          cp /path/to/.env           ~/.openclaw/   # OPENCLAW_GATEWAY_TOKEN
      '';

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/openclaw/openclaw:latest";
      description = "Container image. Use <file:///path/to/image.tar> for a local build.";
    };

    containerName = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "Podman container name.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "adam";
      description = "Host user who owns and manages the container.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/${cfg.user}/.openclaw";
      description = "Host-based OpenClaw state directory (config, workspace, .env).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Gateway UI port on the host.";
    };

    bridgePort = lib.mkOption {
      type = lib.types.port;
      default = 18790;
      description = "Bridge port on the host.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host interface for the published ports.";
    };

    gatewayBind = lib.mkOption {
      type = lib.types.str;
      default = "lan";
      description = "Gateway bind mode inside the container: `lan` or `localhost`.";
    };

    linger = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable systemd lingering for auto-start on boot.";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Remove resource limits and increase startup timeout.";
    };

    extraAPTPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra apt packages to install at image build time (OPENCLAW_IMAGE_APT_PACKAGES).";
    };

    subuidRanges = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [{ startUid = 100000; count = 65536; }];
      description = "subuid ranges for rootless podman.";
    };

    subgidRanges = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [{ startGid = 100000; count = 65536; }];
      description = "subgid ranges for rootless podman.";
    };
  };

  config = lib.mkIf cfg.enable {

    # ─── Rootless Podman ─────────────────────────────────────────────────
    virtualisation.podman = {
      enable = true;
      enableDocker = false;
      requiredUsers = [ cfg.user ];
    };

    # ─── Subuid/subgid ranges for rootless podman ───────────────────────
    users.users.${cfg.user} = {
      isNormalUser = lib.mkDefault true;
      subUidRanges = cfg.subuidRanges;
      subGidRanges = cfg.subgidRanges;
    };

    # ─── Systemd user lingering ──────────────────────────────────────────
    systemd.users.${cfg.user} = lib.mkIf cfg.linger {
      lingering = true;
    };

    # ─── Systemd user service ─────────────────────────────────────────────
    #    Boots on login and survives across reboots via lingering.
    systemd.user.services.openclaw = {
      description = "OpenClaw rootless Podman container";
      after = [ "podman.socket" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10";
        ExecStart = runLine;
        ExecStop = "${getBin pkgs.podman}/bin/podman stop -t 10 ${cfg.containerName}";
        ExecStopPost = "${getBin pkgs.podman}/bin/podman rm -f ${cfg.containerName}";
      };
    };

    # ─── Host CLI convenience variable ───────────────────────────────────
    environment.sessionVariables.OPENCLAW_CONTAINER = cfg.containerName;
    programs.openclaw.enable = true;
  };
}
