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
        && config.hmModules.apps.packages.system.enable
      )
      {
        home.packages = with pkgs; [
          grim
          slurp
          grimblast

          snx-rs

          nh
        ];
      };
}
