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
    ./dolphin.nix
    ./nvf.nix
    ./stylix.nix
    ./nvim
    ./forge.nix
  ];

  options.hmModules.apps = {
    enable = lib.mkEnableOption "apps";
  };

  config = lib.mkIf config.hmModules.apps.enable {
    home.packages = with pkgs; [
      thunderbird

      keepassxc

      vlc

      grim
      slurp
      grimblast

      yazi

      snx-rs

      umu-launcher
      flatpak
      prismlauncher
      ftb-app
      heroic
      ckan
      qbittorrent

      sillytavern

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

