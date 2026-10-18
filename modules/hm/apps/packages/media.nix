{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages.media") {
    home.packages = with pkgs; [
      vlc
      kdePackages.kdenlive
    ];
  };
}
