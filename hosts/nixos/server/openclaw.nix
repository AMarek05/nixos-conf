# OpenClaw Container Guest OS Configuration
# A minimal NixOS VM that runs only the OpenClaw service
{ pkgs, lib, ... }:

{
  imports = [
    ../../../modules/nixos/openclaw/modules/user.nix
    ../../../modules/nixos/openclaw/modules/sops.nix
    ../../../modules/nixos/openclaw/modules/tools-loader.nix
    ../../../modules/nixos/openclaw/modules/systemd.nix
  ];

  # ── Static networking on the virtual ethernet (ve-+) ───────────────────
  networking.hostName = "openclaw";

  networking.interfaces.eth.ipv4.addresses = [
    {
      address = "192.168.100.11";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.100.10";
  networking.nameservers = [ "10.20.20.5" ];

  # ── SOPS ────────────────────────────────────────────────────────────────
  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

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

    extraConfig = {
      gateway.bind = "lan";
    };
  };

  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}