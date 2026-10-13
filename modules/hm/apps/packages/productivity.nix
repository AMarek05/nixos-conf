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
          antigravity-hub
          dbeaver-bin
          libreoffice-stable

          remmina

          alacarte
          evince

          intellij-idea
          rust-rover

          thunderbird
        ];
      };
}
