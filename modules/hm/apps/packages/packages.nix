{ pkgs, lib, config, ... }:
{
  config = lib.mkIf (config.hmModules.apps.packages.enable && config.hmModules.apps.packages.packages.enable) {
    home.packages = with pkgs; [ nh ];
  };
}
