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
        && config.hmModules.apps.packages.productivity.enable
      )
      {
        home.packages = with pkgs; [
          dbeaver-bin
          onlyoffice-desktopeditors
          libreoffice-stable

          alacarte
          evince

          thunderbird
        ];
      };
}
