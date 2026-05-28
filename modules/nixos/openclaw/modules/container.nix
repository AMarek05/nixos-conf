# OpenClaw Container Configuration
#
# Deploys OpenClaw as a lightweight NixOS system container on the host.
# Uses the host's network stack with a static IP on a bridge interface.
# SOPS secrets are handled by the host and bind-mounted into the container.
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
    enable = lib.mkEnableOption "Deploy OpenClaw as a NixOS system container";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "10.20.30.20";
      description = "Static IP for the container on the bridge network.";
    };

    webUiPort = lib.mkOption {
      type = lib.types.port;
      default = 18790;
      description = "Host port that forwards to the gateway inside the container.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openclaw";
      description = "Host path mounted as /var/lib/openclaw inside the container.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "Hostname for the container.";
    };
  };

  config = lib.mkIf cfg.container.enable {
    # NixOS container
    virtualisation.containers.enable = true;

    virtualisation.containers.containersConf = [
      {
        name = "openclaw";
        autoStart = true;
        ensureColonSeparatedRecordOfLocalSystemdUnits = true;

        # Bridge networking — container gets its own NIC on host's bridge
        networkMode = "bridge";

        config = { pkgs, ... }: {
          # Inherit the openclaw module but run as container
          imports = [
            ../../../modules/nixos/openclaw
          ];

          networking.hostName = cfg.container.hostName;
          networking.useNetworkd = false;
          networking.useDHCP = false;

          # Static IP on the bridge
          networking.interfaces.br0.ipv4.addresses = [
            {
              address = cfg.container.ip;
              prefixLength = 24;
            }
          ];

          # Default gateway = host's IP on the bridge
          networking.defaultGateway = "10.20.30.1";

          # Disable unnecessary services in container
          systemd.services."systemd-update-utmp".enable = false;
          systemd.services."systemd-resolved".enable = false;
          systemd.services.getty.enable = false;
          systemd.services.logind.enable = false;

          # AppArmor is handled by the host; not needed in container
          security.apparmor.enable = false;

          # OpenClaw service
          services.openclaw = {
            enable = true;

            bindAddress = "0.0.0.0";
            port = 18789;

            sandboxedExecs.extraBins = {
              "jq" = pkgs.jq.bin;
              "rg" = pkgs.ripgrep;
              "sed" = pkgs.gnused;
              "xxd" = pkgs.xxd;
              "patch" = pkgs.patch;
            };

            servicePath = with pkgs; [ bash ];
          };

          # Mount workspace from host
          fileSystems."/var/lib/openclaw" = {
            device = cfg.container.dataDir;
            fsType = "none";
            options = [ "bind" "rw" ];
          };

          # Mount SOPS decrypted secrets from host
          fileSystems."/run/secrets" = {
            device = "/run/secrets";
            fsType = "none";
            options = [ "bind" "ro" ];
          };

          # Make openclaw available
          environment.systemPackages = with pkgs; [ openclaw ];

          # Container needs git config for commits
          programs.git = {
            enable = true;
            userName = "Claw";
            userEmail = "278452676+amarek-machine@users.noreply.github.com";
          };
        };
      }
    ];

    # Port forward: host port → container IP:18789
    # This is implemented via iptables on the host
    networking.firewall.extraCommands = ''
      # OpenClaw container port forward
      iptables -t nat -A PREROUTING -p tcp --dport ${toString cfg.container.webUiPort} -j DNAT --to-destination ${cfg.container.ip}:${toString cfg.port}
      iptables -t nat -A OUTPUT -p tcp --dport ${toString cfg.container.webUiPort} -j DNAT --to-destination ${cfg.container.ip}:${toString cfg.port}
    '';

    # Allow forwarding to the container
    networking.firewall.extraStopCommands = ''
      iptables -t nat -D PREROUTING -p tcp --dport ${toString cfg.container.webUiPort} -j DNAT --to-destination ${cfg.container.ip}:${toString cfg.port} 2>/dev/null || true
      iptables -t nat -D OUTPUT -p tcp --dport ${toString cfg.container.webUiPort} -j DNAT --to-destination ${cfg.container.ip}:${toString cfg.port} 2>/dev/null || true
    '';
  };
}