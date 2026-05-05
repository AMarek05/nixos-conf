# security/pam.nix — PAM service configurations
{ lib, config }:
let
  cfg = config.modules.security.pam;
in
{
  config = lib.mkIf cfg.enable {
    security.pam.services.hyprlock = { };
  };
}
