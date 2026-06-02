# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

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

  sops.secrets."open-webui-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
    owner = "open-webui";
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
  #
  # We use EnvironmentFile=/run/secrets/minimax-api-key — sops-nix decrypts
  # the secret here at runtime (systemd tmpfiles.d), and systemd's
  # EnvironmentFile= injects it into the service process env. The activation
  # script also writes the same path to ~/.hermes/.env for load_hermes_dotenv.
  services.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
  };

  users.groups.hermes.gid = 970;

  users.users.open-webui = {
    uid = 969;
    group = "open-webui";
    isSystemUser = true;
    description = "Open WebUI";
  };

  users.groups.open-webui.gid = 969;

  # ── Open WebUI ──────────────────────────────────────────────────────
  # Connects to hermes API server at 127.0.0.1:8642
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8280;
    environmentFile = config.sops.templates."open-webui-env".path;
    environment = {
      OPENAI_API_BASE_URL = "http://127.0.0.1:8642/v1";
      WEBUI_AUTH = "False";
    };
    serviceConfig.DynamicUser = false;
  };

  # ── Network ───────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [ 8280 ];

  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
