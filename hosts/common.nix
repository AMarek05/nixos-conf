{ lib, nixpkgs, ... }:
{
  imports = [
    ../modules/defaults.nix
  ];

  programs.home-manager.enable = lib.mkForce true;

  nixpkgs.config.allowUnfree = true;
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.11"; # Please read the comment before changing.
  };
}
