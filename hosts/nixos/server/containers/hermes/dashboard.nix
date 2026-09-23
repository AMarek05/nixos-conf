{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.services.hermes-agent;
in
{
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
        "${lib.getExe pkgs.hermes-agent}"
        "dashboard"
        "--host"
        "0.0.0.0"
        "--port"
        "9119"
        "--no-open"
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
