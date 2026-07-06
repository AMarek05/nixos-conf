{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.hmModules.apps.enable {
    home.packages = with pkgs; [ nh ];
  };
}
