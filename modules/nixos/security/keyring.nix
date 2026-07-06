{ lib, config, ... }:
{
  config = lib.mkIf (config.nixosModules.security.enable && config.nixosModules.security.keyring.enable) {
    security.pam.services.hyprlock = { };

    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
