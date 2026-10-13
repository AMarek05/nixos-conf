{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages.system") {
    home.packages = with pkgs; [
      grim
      slurp
      grimblast

      snx-rs

      baobab
    ];
  };
}
