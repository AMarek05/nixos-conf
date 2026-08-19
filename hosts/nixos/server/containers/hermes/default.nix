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
  fj-wrapper = myLib.fj-wrapper { inherit config pkgs; };

  openclaw-secrets = "${inputs.self}/secrets/openclaw.yaml";
  serv-secrets = "${inputs.self}/secrets/serv.yaml";
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

  sops.secrets."fj-auth" = {
    sopsFile = serv-secrets;
    owner = "hermes";
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

    # All three templates are concatenated into ~/.hermes/.env at activation.
    # hermes reads them via load_hermes_dotenv() at startup.
    environmentFiles = [
      config.sops.templates."hermes-env".path
      config.sops.templates."hermes-api-key-env".path
      config.sops.templates."hermes-discord-env".path
    ];

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

      memory.user_profile_enabled = true;

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

  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Web Dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "hermes-agent.service" ];
    wants = [ "hermes-agent.service" ];

    environment = {
      HOME = cfg.stateDir;
      HERMES_HOME = "${cfg.stateDir}/.hermes";
      HERMES_MANAGED = "true";
    };

    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.stateDir;

      ExecStart = lib.concatStringsSep " " [
        "${inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.full}/bin/hermes"
        "dashboard"
        "--host" "0.0.0.0"
        "--port" "9119"
        "--no-open"
        "--insecure"
        "--skip-build"
      ];

      Restart = "on-failure";
      RestartSec = "5s";

      UMask = "0007";

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [
        cfg.stateDir
      ];
      PrivateTmp = true;
    };

    path = [
      inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.full
      pkgs.bash
      pkgs.coreutils
    ];
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
      OPENAI_API_BASE_URL = "http://127.0.0.1:8642/v1";
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
    fj-wrapper

    pkgs.gawk

    pkgs.python3
    pkgs.nodejs
    pkgs.dig
  ];

  # ── Network ───────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [
    8642
    8080
    9119
  ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}
