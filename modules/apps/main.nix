{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.modules.apps = {
    enable = lib.mkEnableOption "apps";
  };

  config = lib.mkIf config.modules.apps.enable {
    home.packages = with pkgs; [
      thunderbird

      keepassxc

      rustlings

      vlc

      grim
      slurp
      grimblast

      yazi

      mullvad-vpn
      snx-rs

      umu-launcher
      steam
      flatpak
      gamemode
      prismlauncher
      ftb-app
      lutris-free

      nautilus
      alacarte
      evince

      dbeaver-bin
      onlyoffice-desktopeditors
      libreoffice-fresh
    ];

    gtk = {
      enable = lib.mkForce true;
      colorScheme = "dark";
      gtk4.theme = config.gtk.theme;
    };

    programs.firefox.enable = true;
    programs.zen-browser.enable = true;
  };
}
