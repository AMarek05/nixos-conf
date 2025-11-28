{ lib, ... }:
{
  imports = [
    ./git.nix
    ./shell.nix
    ./util.nix
    ./env.nix
    ./links.nix

    ./hyprland.nix

    ./apps/main.nix
    ./apps/stylix.nix

    ./apps/nvf.nix
    ./apps/terminal.nix
  ];

  modules = {
    env.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    util.enable = lib.mkDefault true;
    links.enable = lib.mkDefault true;

    apps.stylix.enable = lib.mkDefault true;
    apps.nvf.enable = lib.mkDefault true;

    hyprland.enable = lib.mkDefault true;
  };
}
