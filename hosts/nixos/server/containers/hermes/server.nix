{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.services.hermes-agent;
  port = 9120;
in
{
  systemd.services.hermes-serve = {
    description = "Hermes Agent Backend Server (headless JSON-RPC/WebSocket gateway)";
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
        "${lib.getExe pkgs.hermes-agent}"
        "serve"
        "--host"
        "0.0.0.0"
        "--port"
        (toString port)
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
      EnvironmentFile = config.sops.templates."hermes-dashboard-env".path;
    };

    path = [
      pkgs.hermes-agent
      pkgs.bash
      pkgs.coreutils
    ];
  };
}
