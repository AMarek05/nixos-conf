{ lib, ... }:
{
  imports = [
    ./git.nix
    ./nvim.nix
    ./shell.nix
    ./util.nix
    ./env.nix
    ./links.nix
    ./hyprland.nix
  ];

  modules.env.enable = lib.mkDefault true;
  modules.git.enable = lib.mkDefault true;
  modules.util.enable = lib.mkDefault true;
  modules.links.enable = lib.mkDefault true;
  modules.nvim.enable = lib.mkDefault true;
  # modules.shell.enable = lib.mkDefault true;
}
