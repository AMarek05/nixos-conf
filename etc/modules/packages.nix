{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.modules.packages = {
    enable = lib.mkEnableOption "core system packages";
  };

  config = lib.mkIf config.modules.packages.enable {
    environment.systemPackages = with pkgs; [
      vim
      git
      man-pages
      rclone
      gparted-full
      alsa-ucm-conf
      alsa-utils
      android-tools
      openssl
      steam-run-free
    ];
  };
}
