{ lib, ... }:
{
  imports = [
    ./common.nix
  ];

  hmModules = {
    apps = {
      stylix.enable = false;
      dolphin.enable = false;

      packages.enable = false;
    };

    caelestia.enable = false;
    hyprland.enable = false;

    terminal.ghostty.enable = false;
  };

  programs.git.signing.key = lib.mkForce "/home/adam/.ssh/git";
}
