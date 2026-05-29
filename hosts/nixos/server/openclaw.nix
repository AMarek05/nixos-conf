# OpenClaw Container Guest OS Configuration
# A minimal NixOS VM that runs only the OpenClaw service
{ pkgs, lib, ... }:

let
  # Bind mount source paths (host paths — same values as host mount destinations)
  ageKeyHost = "/var/lib/sops-nix/age_key";
  workspaceHost = "/var/lib/openclaw/workspace";
in
{
  imports = [
    ../../../modules/nixos/openclaw/modules/user.nix
    ../../../modules/nixos/openclaw/modules/sops.nix
    ../../../modules/nixos/openclaw/modules/tools-loader.nix
    ../../../modules/nixos/openclaw/modules/systemd.nix
  ];

  # ── NAT for container network ────────────────────────────────────────────────
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens18";
  };

  # ── OpenClaw container ─────────────────────────────────────────────────────
  virtualisation.containers.openclaw = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";

    forwardPorts = [
      {
        containerPort = 18789;
        hostPort = 18789;
        protocol = "tcp";
      }
    ];

    bindMounts = {
      "/var/lib/sops-nix/age_key" = {
        hostPath = "/var/lib/sops-nix/age_key";
        isReadOnly = true;
      };
      "/var/lib/openclaw/workspace" = {
        hostPath = "/var/lib/openclaw/workspace";
        isReadOnly = false;
      };
    };
  };

  # ── Static networking on the virtual ethernet (ve-+) ───────────────────
  #   hostAddress  : address on the HOST's end of the veth pair  (gateway for container)
  #   localAddress : address on the CONTAINER's eth0
  networking.interfaces.eth.ipv4.addresses = [
    {
      address = "192.168.100.11";
      prefixLength = 24;
    }
  ];

  # Container uses host's veth end as default gateway
  networking.defaultGateway = "192.168.100.10";

  # DNS via host network
  networking.nameservers = [ "10.20.20.5" ];

  # ── SOPS ────────────────────────────────────────────────────────────────
  # Password store (AGE key shared from host via bind mount)
  sops.age.sshKeyPaths = [ ageKeyHost ];

  # Declarations for all secrets used by the openclaw module
  sops.secrets."nim-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };
  sops.secrets."openrouter-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };
  sops.secrets."minimax-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };
  sops.secrets."gh-token" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };
  sops.secrets."claw-ssh-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };
  sops.secrets."claw-bot-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };

  # ── OpenClaw service ───────────────────────────────────────────────────
  nixosModules.openclaw.enable = true;

  services.openclaw = {
    sandboxedExecs.enable = false;
    tools.enable = false;
    servicePath = with pkgs; [
      bash
      coreutils
      jq
      ripgrep
      gnused
      xxd
      patch
      fd
      nix
    ];

    # Gateway binds to the container's LAN interface (all-container block)
    extraConfig = {
      gateway.bind = "lan";
    };
  };

  # ── Time ────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";

  # ── System identity ─────────────────────────────────────────────────────
  system.stateVersion = "24.11";
}
