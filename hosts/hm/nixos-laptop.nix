{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
  ];

  programs.zsh.shellAliases = {
    nhh = lib.mkForce "nh home switch --cores 4 --max-jobs 1";
  };

  hmModules.hyprland = {
    monitors = lib.mkForce [
      {
        output = "";
        mode = "1920x1080@59.997000";
        position = "auto";
        scale = 1;
      }
    ];

    settings.input.touchpad = {
      natural_scroll = true;
      scroll_factor = 0.3;
    };
  };

  home.packages = with pkgs; [ obs-studio ];

  programs.caelestia.settings.bar.status.showBattery = lib.mkForce true;
}
