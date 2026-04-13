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

      snx-rs

      umu-launcher
      steam
      flatpak
      prismlauncher
      ftb-app
      lutris-free
      heroic
      ckan

      nautilus
      alacarte
      evince

      dbeaver-bin
      onlyoffice-desktopeditors
      libreoffice-fresh
    ];

    programs.firefox.enable = true;
    programs.zen-browser.enable = true;
  };
}
