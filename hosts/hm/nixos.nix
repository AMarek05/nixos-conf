{ pkgs, lib, ... }:
{
  imports = [
    ./common.nix
  ];

  programs.caelestia.settings.general.idle.timeouts = lib.mkForce [
    {
      timeout = 600;
      idleAction = "dpms off";
      returnAction = "dpms on";
    }
  ];

  hmModules.hyprland.monitors = lib.mkForce [
    {
      output = "";
      mode = "1920x1080@74.97";
      position = "auto";
      scale = 1;
    }
  ];

  home.packages = with pkgs; [
    vdpauinfo
  ];
}
