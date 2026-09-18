{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixosModules.system.packages.enable {
    environment.systemPackages = with pkgs; [
      vim
      git
      man-pages
      rclone
      gparted-full
      android-tools
      openssl
      jq
    ];
  };
}
