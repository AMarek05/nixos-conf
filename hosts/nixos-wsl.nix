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
  };
}
