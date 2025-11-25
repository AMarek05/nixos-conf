{ pkgs, ... }:
{
  imports = [
    ../modules/defaults.nix
    ./common.nix
  ];
  home.packages = with pkgs; [
    vdpauinfo
  ];
}
