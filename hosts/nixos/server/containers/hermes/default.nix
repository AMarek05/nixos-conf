# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
{
  pkgs,
  config,
  inputs,
  lib,
  myLib,
  myIp,
  ...
}:
# Dashboard and serve units live in dashboard.nix and server.nix (siblings).
let
  cfg = config.services.hermes-agent;

  hermes-soul-file = pkgs.writeText "SOUL.md" (
    builtins.replaceStrings [ "__HERMES_IP__" ] [ myIp ] (builtins.readFile ./SOUL.md)
  );
  hermes-user-file = pkgs.writeText "USER.md" (
    builtins.replaceStrings [ "__HERMES_IP__" ] [ myIp ] (builtins.readFile ./USER.md)
  );

  agent-secrets = "${inputs.self}/secrets/agent.yaml";
  serv-secrets = "${inputs.self}/secrets/serv.yaml";

  # open-webui runs on the host and reaches the hermes relay via the
  # container's host-side address (myIp = containers.hermes.localAddress).
  hermesApiBaseUrl = "http://${myIp}:8642/v1";
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    myLib.gitWrapper
    myLib.fjWrapper
    ./dashboard.nix
    ./server.nix
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
    sopsFile = agent-secrets;
    owner = "hermes";
  };

  sops.secrets."hermes-bot-key" = {
    sopsFile = agent-secrets;
    owner = "hermes";
  };

  sops.secrets."hermes-api-key" = {
    sopsFile = agent-secrets;
    owner = "hermes";
  };

  sops.secrets."claw-ssh-key" = {
    sopsFile = agent-secrets;
    owner = "hermes";
  };

  sops.secrets."open-webui-api-key" = {
    sopsFile = agent-secrets;
    owner = "root";
    mode = "0444";
  };

  sops.secrets."gh-token-hermes" = {
    sopsFile = agent-secrets;
    key = "gh-token";
    owner = "hermes";
  };

  sops.secrets."fj-auth" = {
    sopsFile = serv-secrets;
    owner = "hermes";
  };

  sops.secrets."dashboard-admin-password" = {
    sopsFile = serv-secrets;
    owner = "hermes";
  };

  sops.templates."open-webui-env" = {
    owner = "open-webui";
    group = "open-webui";
    content = ''
      OPENAI_API_BASE_URLS=https://api.minimax.io/v1;${hermesApiBaseUrl}
      OPENAI_API_KEYS=${config.sops.placeholder."minimax-api-key"};${
        config.sops.placeholder."hermes-api-key"
      }
    '';
  };

  sops.templates."hermes-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      API_SERVER_HOST=0.0.0.0
      API_SERVER_KEY=${config.sops.placeholder."hermes-api-key"}

      MINIMAX_API_KEY=${config.sops.placeholder."minimax-api-key"}
      DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-bot-key"}
      GH_TOKEN=${config.sops.placeholder."gh-token-hermes"}
    '';
  };

  sops.templates."hermes-dashboard-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=adam
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."dashboard-admin-password"}
    '';
  };

  # ── Hermes Agent service ──────────────────────────────────────────────
  # The hermes module's activation script writes cfg.environment and
  # cfg.environmentFiles to ~/.hermes/.env (via load_hermes_dotenv at Python
  # startup). hermes-agent's own _HERMES_PROVIDER_ENV_BLOCKLIST scrubs
  # MINIMAX_API_KEY from tool subprocess environments.
  services.hermes-agent = {
    enable = true;

    package = pkgs.hermes-agent;
    container.enable = false;

    user = "hermes";
    group = "hermes";
    createUser = false;

    stateDir = "/var/lib/hermes";

    environment = {
      DISCORD_HOME_CHANNEL = "1511502650338971758";

      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
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

    mcpServers.fff =
      let
        fffState = "${cfg.stateDir}/.hermes/fff";
        fffBin = inputs.fff.packages.${pkgs.stdenv.hostPlatform.system}.fff-mcp;
      in
      {
        command = "${fffBin}/bin/fff-mcp";
        args = [
          "/var/lib/hermes/workspace"
          "--frecency-db"
          "${fffState}/frecency.db"
          "--history-db"
          "${fffState}/history.db"
          "--log-file"
          "${fffState}/fff-mcp.log"
          "--no-update-check"
        ];
      };

    environmentFiles = [ config.sops.templates."hermes-env".path ];

    settings = {
      model = "minimax/MiniMax-M3";
      gateway.bind = "lan";
      gateway.platforms.discord.gateway_restart_notification = false;

      providers.openai = null;

      discord = {
        enabled = true;
        token = "\${DISCORD_BOT_TOKEN}";
      };

      api_server = {
        enable = true;
        host = "0.0.0.0";
      };

      display = {
        show_reasoning = true;
        reasoning_full = true;
      };

      memory = {
        user_profile_enabled = true;
        memory_char_limit = 10000;
      };

      curator = {
        interval_hours = 24;
        min_idle_hours = 336;
        archive_after_days = 30;
      };

      # ── Prompt / toolset trim ─────────────────────────────────────
      # Pi-style minimalism: cut toolsets that never fire in this
      # container so their JSON schemas (~14.8K tok baseline) don't
      # ship on every turn. Per `hermes_cli/tools_config.py`, the
      # `hermes-discord` default toolset resolves 50 tool definitions;
      # these are the ones that have no caller in this setup.

      agent = {
        disabled_toolsets = [
          "computer_use"
          "kanban"
          "homeassistant"
          "discord_admin"
        ];
        task_completion_guidance = true;
        tool_use_enforcement = "auto";
        environment_probe = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/.hermes/memories 2770 ${cfg.user} ${cfg.group} - -"
    "d ${cfg.stateDir}/.hermes/fff 2770 ${cfg.user} ${cfg.group} - -"

    # L+ (not C): re-points the symlink to the new derivation on every rebuild.
    # C only seeds the file once; subsequent source edits were silently ignored.
    "L+ ${cfg.stateDir}/.hermes/SOUL.md - ${cfg.user} ${cfg.group} - ${hermes-soul-file}"

    "L+ ${cfg.stateDir}/.hermes/memories/USER.md - ${cfg.user} ${cfg.group} - ${hermes-user-file}"
  ];

  systemd.services.hermes-agent.serviceConfig = {
    TimeoutStopSec = "5s";
    KillSignal = lib.mkForce "SIGTERM";
    KillMode = "process";
    SendSIGKILL = false;
  };

  # hermes-dashboard.service and hermes-serve.service live in dashboard.nix and server.nix.

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Tailscale: first-boot login is interactive (same as nixos + nixos-laptop).
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "none";
    openFirewall = false;
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

      ENABLE_PERSISTENT_CONFIG = "False";

      ENABLE_OPENAI_API = "True";
      ENABLE_OLLAMA_API = "False";

      ENABLE_MODEL_FILTER = "False";
      BYPASS_MODEL_ACCESS_CONTROL = "True";

      DEFAULT_MODELS = "MiniMax-M3";
    };
  };

  systemd.services.open-webui.serviceConfig = {
    TimeoutStopSec = lib.mkForce "2s";
    KillSignal = "SIGKILL";
  };

  # ── CLI ───────────────────────────────────────────────────────────────
  environment.systemPackages = [
    pkgs.hermes-agent

    pkgs.gawk

    pkgs.python3
    pkgs.nodejs
    pkgs.dig

    pkgs.agent-browser
  ];

  # Per-container firewall is owned by lib/containers.nix via instances.<name>.ports.
  # OpenWebUI (8080) and the hermes API server (8642) are already in there.

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
