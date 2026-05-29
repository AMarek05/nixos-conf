# OpenClaw Container Guest OS Configuration
# A minimal NixOS VM that runs only the OpenClaw service
{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../../modules/nixos/openclaw
    inputs.sops-nix.nixosModules.sops
  ];

  # ── Static networking on the virtual ethernet (ve-+) ───────────────────
  networking.hostName = "openclaw";
  networking.usePredictableInterfaceNames = false;

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
  networking.firewall.allowedTCPPorts = [ 18789 ];
  nixosModules.openclaw.enable = true;

  services.openclaw = {
    sandboxedExecs.enable = false;
    tools.enable = false;

    servicePath = with pkgs; [
      bash
      coreutils
      jq

      ripgrep
      fd
      gnused

      xxd
      patch

      nix
      neovim
    ];

    extraConfig = {
      tools.exec.security = "full";
      tools.exec.ask = "off";

      gateway = {
        bind = "lan";

        trustedProxies = [
          "192.168.100.10"
          "100.64.0.0/10"
        ];

        controlUi.allowedOrigins = [
          "https://openclaw.amarek.org"
        ];
      };

      plugins.entries = {
        memory-wiki.enabled = true;
      };
    };
  };

  systemd.services.openclaw = {
    serviceConfig = {
      TimeoutStopSpec = "2s";
      KillSignal = "SIGINT";
      KillMode = "control-group";
      SendSIGKILL = true;
    };
  };

  environment.systemPackages = with pkgs; [
    neovim
    cargo
    git
    gh

    gnused
    fd
    ripgrep
  ];

  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
