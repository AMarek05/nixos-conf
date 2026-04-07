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

    gtk = {
      enable = lib.mkForce true;
      colorScheme = "dark";
      gtk4.theme = config.gtk.theme;
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style.name = "adwaita-dark";
    };

    programs.firefox.enable = true;
    programs.zen-browser.enable = true;
  };
}
