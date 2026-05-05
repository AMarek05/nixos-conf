{ lib, ... }:
{
  options.modules.security = {
    enable = lib.mkEnableOption "security (gnupg, pam, dconf, gnome-keyring)";
  };

  config = lib.mkIf config.modules.security.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };

    security.pam.services.hyprlock = { };

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
