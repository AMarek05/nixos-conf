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
  cfg = config.services.hermes-agent;

  hermes-soul-file = pkgs.writeText "SOUL.md" (builtins.readFile ./SOUL.md);
  hermes-user-file = pkgs.writeText "USER.md" (builtins.readFile ./USER.md);

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

  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "2s";
    };
  };

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
    sopsFile = ../../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."hermes-bot-key" = {
    sopsFile = ../../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."hermes-api-key" = {
    sopsFile = ../../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."claw-ssh-key" = {
    sopsFile = ../../../../secrets/openclaw.yaml;
    owner = "hermes";
  };

  sops.secrets."open-webui-api-key" = {
    sopsFile = ../../../../secrets/openclaw.yaml;
    owner = "root";
    mode = "0444";
  };

  sops.templates."open-webui-env" = {
    owner = "open-webui";
    group = "open-webui";
    content = ''
      OPENAI_API_KEY=${config.sops.placeholder."open-webui-api-key"}
    '';
  };

  sops.templates."hermes-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      MINIMAX_API_KEY=${config.sops.placeholder."minimax-api-key"}
    '';
  };

  sops.templates."hermes-discord-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-bot-key"}
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

    # All three templates are concatenated into ~/.hermes/.env at activation.
    # hermes reads them via load_hermes_dotenv() at startup.
    environmentFiles = [
      config.sops.templates."hermes-env".path
      config.sops.templates."hermes-api-key-env".path
      config.sops.templates."hermes-discord-env".path
    ];

    settings = {
      model = "minimax/MiniMax-M2.7";
      gateway.bind = "lan";
      providers.openai = null;

      discord = {
        enabled = true;
        token = lib.mkForce config.sops.placeholder."hermes-bot-key";
      };

      api_server = {
        enable = true;
        host = "0.0.0.0";
      };

      memory.user_profile_enabled = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/.hermes/memories 2770 ${cfg.user} ${cfg.group} - -"

    "C ${cfg.stateDir}/.hermes/SOUL.md 0640 ${cfg.user} ${cfg.group} - ${hermes-soul-file}"

    "C ${cfg.stateDir}/.hermes/memories/USER.md 0640 ${cfg.user} ${cfg.group} - ${hermes-user-file}"
  ];

  systemd.services.hermes-agent.serviceConfig = {
    TimeoutStopSec = "2s";
    KillSignal = lib.mkForce "SIGKILL";
    KillMode = "control-group";
    SendSIGKILL = true;
  };

  users.users.hermes = {
    uid = 970;
    group = "hermes";
    isSystemUser = true;
    home = "/var/lib/hermes";
    description = "Hermes Agent";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
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
    environmentFile = config.sops.templates."open-webui-env".path;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      WEBUI_AUTH = "False";
      OPENAI_API_BASE_URL = "http://192.168.100.12:8642/v1";
    };
  };

  systemd.services.open-webui.serviceConfig = {
    TimeoutStopSec = lib.mkForce "2s";
    KillSignal = "SIGKILL";
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
