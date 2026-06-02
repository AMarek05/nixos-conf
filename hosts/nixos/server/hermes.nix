# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
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

in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: pkgs.lib.hasPrefix "open-webui" pkg.pname;

  # ── Static networking on the virtual ethernet (ve-+) ───────────────────
  networking.hostName = "hermes";
  networking.usePredictableInterfaceNames = false;

  networking.interfaces.eth.ipv4.addresses = [
    {
      address = "192.168.100.12";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.100.10";
  networking.nameservers = [ "10.20.20.5" ];

  # ── SOPS ────────────────────────────────────────────────────────────────
  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."minimax-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."hermes-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."claw-ssh-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."open-webui-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
    owner = "open-webui";
  };

  sops.templates."hermes-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      MINIMAX_API_KEY=${config.sops.placeholder."minimax-api-key"}
    '';
  };

  sops.templates."hermes-api-key-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      API_SERVER_HOST=0.0.0.0
      API_SERVER_KEY=${config.sops.placeholder."hermes-api-key"}
    '';
  };

  # ── Hermes Agent service ──────────────────────────────────────────────
  # The hermes module's activation script writes cfg.environment and
  # cfg.environmentFiles to ~/.hermes/.env (via load_hermes_dotenv at Python
  # startup). hermes-agent's own _HERMES_PROVIDER_ENV_BLOCKLIST scrubs
  # MINIMAX_API_KEY from tool subprocess environments.
  services.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.full;
    container.enable = false;

    user = "hermes";
    group = "hermes";
    createUser = false;

    stateDir = "/var/lib/hermes";

    # Both templates are concatenated into ~/.hermes/.env at activation.
    # hermes reads them via load_hermes_dotenv() at startup.
    environmentFiles = [
      config.sops.templates."hermes-env".path
      config.sops.templates."hermes-api-key-env".path
    ];

    settings = {
      model = "minimax/MiniMax-M2.7";
      gateway.bind = "lan";
      providers.openai = null;
      api_server = {
        enable = true;
        host = "0.0.0.0";
      };
    };
  };

  systemd.services.hermes-agent.serviceConfig = {
    TimeoutStopSec = "2s";
    KillSignal = "SIGINT";
    KillMode = "control-group";
    SendSIGKILL = true;
    DefaultTimeoutStopSec = lib.mkForce "5s";
  };

  users.users.hermes = {
    uid = 970;
    group = "hermes";
    isSystemUser = true;
    home = "/var/lib/hermes";
    description = "Hermes Agent";
    shell = pkgs.bash;
  };

  users.groups.hermes.gid = 970;

  users.users.open-webui = {
    uid = 969;
    group = "open-webui";
    isSystemUser = true;
    description = "Open WebUI";
  };

  users.groups.open-webui.gid = 969;

  # ── OpenWebUI ─────────────────────────────────────────────────────────────
  services.open-webui = {
    enable = true;
    package = pkgs.open-webui;
    stateDir = "/var/lib/open-webui";
    host = "0.0.0.0";
    port = 8080;
    openFirewall = false;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      # Point to Hermes API server

      WEBUI_AUTH = "False";

      OPENAI_API_BASE_URL = "http://192.168.100.12:8642/v1";
      OPENAI_API_KEY = config.sops.secrets."open-webui-api-key".path;
    };
  };

  # ── CLI ───────────────────────────────────────────────────────────────
  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.full
    git-wrapper
  ];

  # ── Network ───────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [
    8642
    8080
  ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
