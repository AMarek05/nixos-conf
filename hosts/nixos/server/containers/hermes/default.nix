# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
{
  pkgs,
  config,
  inputs,
  lib,
  myLib,
  ...
}:
let
  cfg = config.services.hermes-agent;

  hermes-soul-file = pkgs.writeText "SOUL.md" (builtins.readFile ./SOUL.md);
  hermes-user-file = pkgs.writeText "USER.md" (builtins.readFile ./USER.md);

  git-wrapper = myLib.git-wrapper { inherit config pkgs; };

  openclaw-secrets = "${inputs.self}/secrets/openclaw.yaml";
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = lib.mkForce "2s";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: pkgs.lib.hasPrefix "open-webui" pkg.pname;

  # ── SOPS ────────────────────────────────────────────────────────────────
  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."minimax-api-key" = {
    sopsFile = openclaw-secrets;
    owner = "hermes";
  };

  sops.secrets."hermes-bot-key" = {
    sopsFile = openclaw-secrets;
    owner = "hermes";
  };

  sops.secrets."hermes-api-key" = {
    sopsFile = openclaw-secrets;
    owner = "hermes";
  };

  sops.secrets."claw-ssh-key" = {
    sopsFile = openclaw-secrets;
    owner = "hermes";
  };

  sops.secrets."open-webui-api-key" = {
    sopsFile = openclaw-secrets;
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

    environment = {
      DISCORD_HOME_CHANNEL = "1511502650338971758";
    };

    # MCP servers — see https://github.com/MiniMax-AI/MiniMax-Coding-Plan-MCP.
    # web_search (POST /v1/coding_plan/search) and understand_image become
    # available as MCP tools, replacing the unreliable DDGS fallback.
    #
    # pkgs.minimax-coding-plan-mcp brings its own Python interpreter and all
    # deps (mcp, python-dotenv, requests, ...) — no uv/uvx needed and the
    # binary is fully NixOS-compatible (the cpython uvx downloads is not).
    #
    # MINIMAX_API_KEY is interpolated at MCP-spawn time by hermes's
    # tools.mcp_tool._interpolate_env_vars from its own os.environ, which
    # is populated by load_hermes_dotenv() from ~/.hermes/.env — the file
    # built at activation time from cfg.environmentFiles (the SOPS-rendered
    # "hermes-env" template). The key never appears in cfg.environment
    # (which would export it to every subprocess) nor in config.yaml.

    mcpServers.minimax-coding-plan = {
      command = "${pkgs.minimax-coding-plan-mcp}/bin/minimax-coding-plan-mcp";
      args = [ ];
      env.MINIMAX_API_KEY = "\${MINIMAX_API_KEY}";
      env.MINIMAX_API_HOST = "https://api.minimax.io";
    };

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
        token = "\${DISCORD_BOT_TOKEN}";
      };

      api_server = {
        enable = true;
        host = "0.0.0.0";
      };

      memory.user_profile_enabled = true;

      curator = {
        interval_hours = 24;
        min_idle_hours = 336;
        archive_after_days = 30;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/.hermes/memories 2770 ${cfg.user} ${cfg.group} - -"

    "C ${cfg.stateDir}/.hermes/SOUL.md 0640 ${cfg.user} ${cfg.group} - ${hermes-soul-file}"

    "C ${cfg.stateDir}/.hermes/memories/USER.md 0640 ${cfg.user} ${cfg.group} - ${hermes-user-file}"
  ];

  systemd.services.hermes-agent.serviceConfig = {
    TimeoutStopSec = "5s";
    KillSignal = lib.mkForce "SIGTERM";
    KillMode = "process";
    SendSIGKILL = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

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

    package =
      # let
      #   stablePkgs = import inputs.nixpkgs-stable {
      #     system = pkgs.stdenv.hostPlatform.system;
      #     config.allowUnfree = true;
      #   };
      # in
      pkgs.open-webui;

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
    pkgs.gawk

    pkgs.python3
    pkgs.nodejs
    pkgs.dig
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
