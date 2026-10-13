{ lib, config, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "security.keyring") {
    security.pam.services.hyprlock = { };

    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
