{ lib, ... }:
{
  imports = [
    ./common.nix
  ];

  programs.zsh.shellAliases = {
    nhh = lib.mkForce "nh home switch --cores 4 --max-jobs 1";
  };

  wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [ ", 1920x1080@59.997000, auto, 1" ];
    input.touchpad = {
      natural_scroll = true;
      scroll_factor = 0.3;
    };
  };

  programs.caelestia.settings.bar.status.showBattery = lib.mkForce true;
}
