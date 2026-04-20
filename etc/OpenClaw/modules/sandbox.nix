# OpenClaw Sandbox Configuration
#
# This module configures the sandbox environment for OpenClaw's tools,
# ensuring that file operations are restricted to the designated workspace.

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
    # AppArmor profile for additional sandboxing (optional but recommended)
    security.apparmor.policies = lib.mkIf config.security.apparmor.enable {
      openclaw = {
        state = "enforce";

        profile = ''
          ${lib.getExe cfg.package} {
            # Basic capabilities
            capability dac_read_search,
            capability dac_override,

            # Network access for API calls
            network inet stream,
            network inet6 stream,
            network unix stream,
            
            # Read access to system files
            /etc/resolv.conf r,
            /etc/hosts r,
            /etc/nsswitch.conf r,
            /etc/ssl/certs/** r,
            /nix/store/** r,
            
            # Full access to workspace
            ${cfg.workspace}/** rwl,
            ${cfg.workspace}/workspace/** rwl,
            ${cfg.workspace}/tools/** rwl,
            
            # Deny everything else
            deny /** rwlx,
            deny @{PROC}/** rwlx,
            deny /sys/** rwlx,
          }
        '';
      };
    };
  };
}
