{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.hmModules.apps.packages.enable {
    home.packages = with pkgs; [ nh ];
  };
}
