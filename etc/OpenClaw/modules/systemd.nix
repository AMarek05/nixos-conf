# OpenClaw Hardened SystemD Service Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
  sandbox = cfg.sandboxedExecs;

  baselineApprovals = pkgs.writeText "exec-approvals.json" (
    builtins.toJSON {
      version = 1;
      defaults = {
        security = "allowlist";
        ask = "on-miss";
        askFallback = "deny";
        autoAllowSkills = false;
        allowlist = [ "${sandbox.package}/bin/*" ];
      };

      agents.main = {
        security = "allowlist";
        ask = "on-miss";
        allowlist = [ "${sandbox.package}/bin/*" ];
      };
    }
  );

  # Base JSON structure
  baseConfig = {
    gateway = {
      mode = "local";
      port = cfg.port;
      bind = "loopback";
    };

    agents.defaults = {
      workspace = cfg.workspace;

      model.primary = cfg.defaultModel;
      models."${cfg.defaultModel}".alias = cfg.modelAlias;
    };

    tools.deny = [
      "group:ui"
      "group:media"
      "shell"
      "cron"
      "code_execution"
    ];

    tools.exec = {
      host = "gateway";

      security = "allowlist";
      ask = "on-miss";

      pathPrepend = [ "${sandbox.package}/bin" ];

      strictInlineEval = true; # Forces prompts for python/node inline evals

      safeBinTrustedDirs = [ "${sandbox.package}/bin" ];

      safeBins = [
        "cut"
        "uniq"
        "head"
        "tail"
        "tr"
        "wc"
        "jq"
      ];

      safeBinProfiles = {
        jq = {
          minPositional = 0;
          maxPositional = 0;
          allowedValueFlags = [
            "-n"
            "-e"
            "-r"
            "-j"
            "-c"
            "-M"
            "-C"
            "-S"
            "-R"
            "-s"
          ];
          deniedFlags = [
            "-f"
            "--from-file"
            "--argfile"
            "--rawfile"
            "--slurpfile"
            "-L"
            "--library-path"
          ];
        };
      };
    };

    env.shellEnv.enabled = false;
  };

  finalConfig = lib.recursiveUpdate baseConfig cfg.extraConfig;
  openclawConfigFile = pkgs.writeText "openclaw.json" (builtins.toJSON finalConfig);

  openclawLauncher = pkgs.writeShellScript "openclaw-launcher" ''
    set -euo pipefail

    # Re-hydrate the PATH from nothing
    export PATH="${lib.makeBinPath (cfg.servicePath)}"

    # Pass all arguments to the real binary
    exec ${lib.getExe cfg.package} gateway --verbose "$@"
  '';

in
{
  config = lib.mkIf cfg.enable {
    systemd.services.openclaw = {
      description = "OpenClaw AI Gateway (Hardened)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "sops-nix.service"
        "apparmor.service"
      ];
      requires = [ "apparmor.service" ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];

      path = cfg.servicePath;

      environment = {
        SHELL = "${pkgs.bash}/bin/bash";
        OPENCLAW_LOAD_SHELL_ENV = "0";

        GIT_AUTHOR_NAME = "Claw";
        GIT_AUTHOR_EMAIL = "278452676+amarek-machine@users.noreply.github.com";
        GIT_COMITTER_NAME = "Claw";
        GIT_COMITTER_EMAIL = "278452676+amarek-machine@users.noreply.github.com";

      }
      // cfg.environment;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.workspace;

        ExecStart = lib.mkForce "${openclawLauncher}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";

        # Hardening & Memory
        ProtectSystem = "full";
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;

        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;

        MemoryDenyWriteExecute = false;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;

        ReadOnlyPaths = [
          "/nix/store"
          "/etc/resolv.conf"
          "/run/secrets"
        ];

        ReadWritePaths = [ cfg.workspace ];

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
      };

      preStart = ''
          # Ensure Agent directory exists
            ${pkgs.coreutils}/bin/mkdir -p ${cfg.homedir}/.openclaw/agents/main/agent

            # 1. Sync Global Config & Preserve Token
            if [ -f ${cfg.workspace}/.openclaw/openclaw.json ]; then
              TOKEN=$(${pkgs.jq}/bin/jq -r '.gateway.auth.token // "null"' ${cfg.homedir}/.openclaw/openclaw.json)
              ${pkgs.jq}/bin/jq --arg tok "$TOKEN" \
                'if $tok != "null" then .gateway.auth.token = $tok else . end' \
                ${openclawConfigFile} > ${cfg.homedir}/.openclaw/openclaw.json
            else
              ${pkgs.coreutils}/bin/cp ${openclawConfigFile} ${cfg.homedir}/.openclaw/openclaw.json
            fi

            # 2. Inject Secrets into Agent Auth Profile (NESTED PROFILES SCHEMA)
            ${pkgs.jq}/bin/jq -n \
              --arg nv_key "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."nim-api-key".path})" \
              --arg mn_key "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."minimax-api-key".path})" \
              --arg or_key "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."openrouter-api-key".path})" \
              '{
                "profiles": {
                  "nvidia-nim:default": {
                    "type": "api_key",
                    "provider": "nvidia-nim",
                    "key": $nv_key
                  },
                  "openrouter:default": {
                    "type": "api_key",
                    "provider": "openrouter",
                    "key": $or_key
                  },
                  "minimax:global": {
                    "type": "api_key",
                    "provider": "minimax",
                    "key": "$mn_key"
                  }
                }
              }' \
              > ${cfg.homedir}/.openclaw/agents/main/agent/auth-profiles.json

            APPROVALS_FILE="${cfg.homedir}/.openclaw/exec-approvals.json"

        if [ -f "$APPROVALS_FILE" ]; then
          # We merge the Nix baseline with the existing file.
          # We map all entries to objects to fix the "Cannot index string" error.
          ${pkgs.jq}/bin/jq --slurpfile base ${baselineApprovals} '
            ($base[0] * .) | 
            .agents.main.allowlist = (
              (($base[0].agents.main.allowlist // []) + (.agents.main.allowlist // [])) 
              | map(if type == "string" then {pattern: .} else . end) 
              | unique_by(.pattern)
            )
          ' "$APPROVALS_FILE" > "$APPROVALS_FILE.tmp"

          ${pkgs.coreutils}/bin/mv "$APPROVALS_FILE.tmp" "$APPROVALS_FILE"
        else
          # Fresh install: just copy the baseline
          ${pkgs.coreutils}/bin/cp --no-preserve=mode,ownership ${baselineApprovals} "$APPROVALS_FILE"
        fi

            ${pkgs.coreutils}/bin/chmod 600 ${cfg.homedir}/.openclaw/openclaw.json
            ${pkgs.coreutils}/bin/chmod 600 ${cfg.homedir}/.openclaw/agents/main/agent/auth-profiles.json
            ${pkgs.coreutils}/bin/chmod 600 "$APPROVALS_FILE"
      '';

      postStop = ''
        rm -rf ${cfg.workspace}/tmp/* 2>/dev/null || true
      '';

    };
  };
}
