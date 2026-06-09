# OpenClaw Container Guest OS Configuration
# A minimal NixOS VM that runs only the OpenClaw service
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

let
  git-wrapper = pkgs.writeShellScriptBin "git" ''
    set -euo pipefail

    SSH_KEY_PATH="${config.sops.secrets."claw-ssh-key".path}"

    if [[ -f "$SSH_KEY_PATH" ]]; then
      # Create a persistent allowedSignersFile once (reuse on subsequent calls)
      # Format: "<principal> <key-type> <key>" — ssh-keygen output lacks the principal
      SIGNERS_FILE="$HOME/.ssh/allowed_signers"
      if [[ ! -f "$SIGNERS_FILE" ]]; then
        PUBKEY=$(${pkgs.openssh}/bin/ssh-keygen -y -f "$SSH_KEY_PATH" 2>/dev/null)
        echo "278452676+amarek-machine@users.noreply.github.com $PUBKEY" > "$SIGNERS_FILE"
      fi

      # Configure git to use this signers file for verification
      ${pkgs.git}/bin/git config --global gpg.ssh.allowedSignersFile "$SIGNERS_FILE"


      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"

      # Execute the real git, injecting the SSH signing rules statelessly
      exec ${pkgs.git}/bin/git \
        -c user.name="Claw" \
        -c user.email="278452676+amarek-machine@users.noreply.github.com" \
        -c g.branch.autosetuprebase=always \
        -c gpg.format=ssh \
        -c user.signingkey="$SSH_KEY_PATH" \
        -c commit.gpgsign=true \
        "$@"
    else
      # Fallback to standard git if the key hasn't been provisioned yet
      exec ${pkgs.git}/bin/git "$@"
    fi
  '';

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
in

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
