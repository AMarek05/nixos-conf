# OpenClaw Container Guest OS Configuration
# A minimal NixOS VM that runs only the OpenClaw service
{
  pkgs,
  config,
  inputs,
  lib,
  myLib,
  ...
}:

let
  git-wrapper = myLib.git-wrapper { inherit config pkgs; };

  gh-wrapper = pkgs.writeShellScriptBin "gh" ''
    set -euo pipefail

    GH_TOKEN_PATH="${config.sops.secrets."gh-token".path}"

    if [[ -f "$GH_TOKEN_PATH" ]]; then
      GH_TOKEN=$(${pkgs.coreutils}/bin/cat "$GH_TOKEN_PATH")
      if [[ -n "$GH_TOKEN" ]]; then
        export GH_TOKEN
      fi
    fi

    exec ${pkgs.gh}/bin/gh "$@"
  '';

  openclaw-secrets = "${inputs.self}/secrets/openclaw.yaml";
in

{
  imports = [
    "${inputs.self}/modules/nixos/openclaw"
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
    sopsFile = openclaw-secrets;
  };
  sops.secrets."openrouter-api-key" = {
    sopsFile = openclaw-secrets;
  };
  sops.secrets."minimax-api-key" = {
    sopsFile = openclaw-secrets;
  };
  sops.secrets."gh-token" = {
    sopsFile = openclaw-secrets;
  };
  sops.secrets."claw-ssh-key" = {
    sopsFile = openclaw-secrets;
  };
  sops.secrets."claw-bot-key" = {
    sopsFile = openclaw-secrets;
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
          "https://openclaw.amarek.pl"
        ];
      };

      plugins.entries = {
        memory-wiki.enabled = true;
      };
    };
  };

  systemd.services.openclaw = {
    serviceConfig = {
      DefaultTimeoutStopSec = lib.mkForce "5s";
      TimeoutStopSpec = "2s";
      KillSignal = "SIGINT";
      KillMode = "control-group";
      SendSIGKILL = true;
    };
  };

  users.groups.openclaw.gid = 968;

  environment.systemPackages =
    (with pkgs; [
      neovim
      cargo

      gnused
      fd
      ripgrep
    ])
    ++ [
      git-wrapper
      gh-wrapper
    ];

  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
