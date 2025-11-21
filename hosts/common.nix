{ inputs, pkgs, ... }:
let

in
{
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  home.packages = with pkgs; [
    gnumake
    shellcheck
    python3
    gcc
    nodejs
    zig

    kitty
    ghostty
  ];

  imports = [
    inputs.stylix.homeModules.stylix
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
