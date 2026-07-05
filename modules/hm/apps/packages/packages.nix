{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.hmModules.apps.packages.enable {
    home.packages = with pkgs; [
      thunderbird

      vlc
      kdePackages.kdenlive

      grim
      slurp
      grimblast

      snx-rs

      umu-launcher
      flatpak
      prismlauncher
      ftb-app
      heroic
      ckan
      qbittorrent

      alacarte
      evince

      dbeaver-bin
      onlyoffice-desktopeditors
      libreoffice-fresh
    ];
  };
}
