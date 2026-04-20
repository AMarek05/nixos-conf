# OpenClaw User and Group Configuration
# Creates a dedicated, isolated user for running OpenClaw

{
  config,
  lib,
  ...
}:

let
  cfg = config.services.openclaw;
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.workspace;
      description = "OpenClaw AI Gateway service user";

      # No password login
      hashedPassword = "!";
    };

    users.groups.${cfg.group} = { };

    # Ensure workspace exists with correct permissions
    systemd.tmpfiles.rules = [
      # Main workspace
      "d ${cfg.workspace} 0700 ${cfg.user} ${cfg.group} -"

      # Configuration directory
      "d ${cfg.workspace}/.openclaw 0700 ${cfg.user} ${cfg.group} -"

      # Tools directory (where custom, pending tools are stored)
      "d ${cfg.workspace}/tools 0750 ${cfg.user} ${cfg.group} -"

      # Logs directory
      "d ${cfg.workspace}/logs 0700 ${cfg.user} ${cfg.group} -"

      # Sessions directory
      "d ${cfg.workspace}/.openclaw/sessions 0700 ${cfg.user} ${cfg.group} -"

      # Credentials directory
      "d ${cfg.workspace}/.openclaw/credentials 0700 ${cfg.user} ${cfg.group} -"
    ];
  };
}
