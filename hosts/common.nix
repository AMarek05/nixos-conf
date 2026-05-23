{ lib, pkgs, ... }:
{
  imports = [
    ../modules/hm/default.nix
  ];

  # Apply lix as default nix parser replacement
  nix.package = pkgs.lix;

  programs.home-manager.enable = lib.mkForce true;

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.11"; # Please read the comment before changing.
  };
}