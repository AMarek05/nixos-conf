{ lib, ... }:
{
  imports = [
    ./common.nix
  ];

  modules = {
    hyprland.enable = lib.mkForce false;
    apps.enable = lib.mkForce false;
    apps.stylix.enable = lib.mkForce false;
  };

  programs = {
    firefox.enable = lib.mkForce false;
    zen-browser.enable = lib.mkForce false;
    ghostty.enable = lib.mkForce false;
  };

  home.sessionVariables.TERM = "xterm-256color";
}
