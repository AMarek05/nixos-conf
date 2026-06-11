{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.hmModules.apps.packages;
in
{
  options.hmModules.apps.packages.enable = lib.mkEnableOption "Assorted apps";

  config = lib.mkIf cfg.enable {
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

    programs.firefox = {
      enable = true;

      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };

    programs.zen-browser.enable = true;
  };
}
