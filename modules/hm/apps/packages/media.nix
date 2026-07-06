{ pkgs, lib, config, ... }:
{
  config = lib.mkIf (config.hmModules.apps.enable && config.hmModules.apps.packages.enable && config.hmModules.apps.packages.media.enable) {
    home.packages = with pkgs; [
      vlc
      kdePackages.kdenlive
    ];
  };
}
