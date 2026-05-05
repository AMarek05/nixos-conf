# services/gnome-keyring.nix — GNOME keyring + PAM integration
{ lib, config }:
let
  cfg = config.modules.services.gnome-keyring;
in
{
  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
