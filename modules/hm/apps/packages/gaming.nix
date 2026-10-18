{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages.gaming") {
    home.packages = with pkgs; [
      umu-launcher
      flatpak
      prismlauncher
      ftb-app
      heroic
      ckan
      qbittorrent
      openmw
    ];
  };
}
