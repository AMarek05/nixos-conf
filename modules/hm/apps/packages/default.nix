{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages") {
    home.packages = with pkgs; [ nh ];
  };
}
