# OpenClaw User and Group Configuration
# Creates a dedicated, isolated user for running OpenClaw

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "OpenClaw AI Gateway service user";

      isSystemUser = true;
      group = cfg.group;
      shell = pkgs.bash;

      home = cfg.homedir;

      # No password login
      hashedPassword = "!";
    };

    users.groups.${cfg.group} = { };

    # Ensure workspace exists with correct permissions
    systemd.tmpfiles.rules = [
      # User homedit
      "d ${cfg.homedir} 0750 ${cfg.user} ${cfg.group} -"

      # Main workspce
      "d ${cfg.workspace} 2770 ${cfg.user} ${cfg.group} -"

      # Set sticky permissions
      "a+ ${cfg.workspace} - - - - default:user::rw-,default:group::rw-,default:other::---"

      # Configuration directory
      "d ${cfg.homedir}/.openclaw 0700 ${cfg.user} ${cfg.group} -"
      "a+ ${cfg.homedir}/.openclaw - - - - default:user::rwx,default:group::---,default:other::---"

      # Logs directory
      "d ${cfg.workspace}/logs 0700 ${cfg.user} ${cfg.group} -"

      # Sessions directory
      "d ${cfg.homedir}/.openclaw/sessions 0700 ${cfg.user} ${cfg.group} -"

      # Credentials directory
      "d ${cfg.homedir}/.openclaw/credentials 0700 ${cfg.user} ${cfg.group} -"
    ];
  };
}
