{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.hyprland = {
    enable = false;

    withUWSM = true;
    xwayland.enable = true;
  };
}
