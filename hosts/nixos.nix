{ pkgs, lib, ... }:
{
  imports = [
    ./common.nix
    ../../modules/nixos/openclaw
  ];

  programs.caelestia.settings.general.idle.timeouts = lib.mkForce [
    {
      timeout = 600;
      idleAction = "dpms off";
      returnAction = "dpms on";
    }
  ];

  home.packages = with pkgs; [
    vdpauinfo
    rimsort
  ];
}