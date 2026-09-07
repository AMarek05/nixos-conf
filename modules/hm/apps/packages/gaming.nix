{
  pkgs,
  lib,
  config,
  ...
}:
{
  config =
    lib.mkIf
      (
        config.hmModules.apps.enable
        && config.hmModules.apps.packages.enable
        && config.hmModules.apps.packages.gaming.enable
      )
      {
        home.packages = with pkgs; [
          umu-launcher
          flatpak
          prismlauncher
          ftb-app
          heroic
          ckan
          qbittorrent
        ];
      };
}
