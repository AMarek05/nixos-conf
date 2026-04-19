# OpenClaw Hardened SystemD Service Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
  basePath = ../../OpenClaw;

  # Base JSON structure (Secret-free)
  baseConfig = {
    gateway = {
      mode = "local";
      port = cfg.port;
      bind = "loopback";
    };
    agents.defaults.workspace = cfg.workspace;
  };

  finalConfig = lib.recursiveUpdate baseConfig cfg.extraConfig;
  openclawConfigFile = pkgs.writeText "openclaw.json" (builtins.toJSON finalConfig);
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.openclaw = {
      description = "OpenClaw AI Gateway (Hardened)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.workspace;

        # Load environment variables from SOPS template
        EnvironmentFile = config.sops.templates."openclaw-env".path;

        ExecStart = "${lib.getExe cfg.package} gateway";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";

        # Hardening & Memory
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        MemoryDenyWriteExecute = false;

        # Add /run/secrets to the sandbox so the script can read the API key
        ReadOnlyPaths = [
          "/nix/store"
          "/etc/resolv.conf"
          "/run/secrets"
        ]
        ++ lib.optional (basePath != null) basePath;

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
        mkdir -p ${cfg.workspace}/.openclaw/agents/main/agent

        # 1. Sync Global Config & Preserve Token
        if [ -f ${cfg.workspace}/.openclaw/openclaw.json ]; then
          TOKEN=$(${pkgs.jq}/bin/jq -r '.gateway.auth.token // "null"' ${cfg.workspace}/.openclaw/openclaw.json)
          ${pkgs.jq}/bin/jq --arg tok "$TOKEN" \
            'if $tok != "null" then .gateway.auth.token = $tok else . end' \
            ${openclawConfigFile} > ${cfg.workspace}/.openclaw/openclaw.json
        else
          cp ${openclawConfigFile} ${cfg.workspace}/.openclaw/openclaw.json
        fi

        # 2. Inject Secrets into Agent Auth Profile (NESTED PROFILES SCHEMA)
        ${pkgs.jq}/bin/jq -n \
          --arg nv_key "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."nim-api-key".path})" \
          --arg or_key "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."openrouter-api-key".path})" \
          '{
            "profiles": {
              "nvidia:default": {
                "type": "api_key",
                "provider": "nvidia",
                "key": $nv_key
              },
              "openrouter:default": {
                "type": "api_key",
                "provider": "openrouter",
                "key": $or_key
              }
            }
          }' \
          > ${cfg.workspace}/.openclaw/agents/main/agent/auth-profiles.json

        chmod 600 ${cfg.workspace}/.openclaw/openclaw.json
        chmod 600 ${cfg.workspace}/.openclaw/agents/main/agent/auth-profiles.json
      '';

      postStop = ''

        rm -rf ${cfg.workspace}/tmp/* 2>/dev/null || true

      '';

    };

    networking.firewall.extraCommands = lib.mkIf config.networking.firewall.enable ''
      iptables -A nixos-fw -p tcp --dport ${toString cfg.port} -s 127.0.0.1 -j ACCEPT

      iptables -A nixos-fw -p tcp --dport ${toString cfg.port} -j DROP

      ip6tables -A nixos-fw -p tcp --dport ${toString cfg.port} -s ::1 -j ACCEPT

      ip6tables -A nixos-fw -p tcp --dport ${toString cfg.port} -j DROP
    '';
  };
}
