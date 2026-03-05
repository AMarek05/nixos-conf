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
      heroic

      nautilus
      alacarte
      evince

      rstudio
      dbeaver-bin
      onlyoffice-desktopeditors
      libreoffice-fresh
    ];

    gtk = {
      enable = lib.mkForce true;
      colorScheme = "dark";
    };

    programs.firefox.enable = true;
    programs.zen-browser = {
      enable = true;
      suppressXdgMigrationWarning = true;
    };
  };
}
