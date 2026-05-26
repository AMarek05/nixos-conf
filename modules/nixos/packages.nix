{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.packages = {
    enable = lib.mkEnableOption "core system packages";
  };

  config = lib.mkIf config.nixosModules.packages.enable {
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
