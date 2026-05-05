# packages/system.nix — core system packages
{ pkgs }:
{
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
  ];
}
