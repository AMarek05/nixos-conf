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
    ./apps/nvf.nix
    ./apps/stylix.nix
    ./apps/terminal.nix
  ];

  modules = {
    env.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    util.enable = lib.mkDefault true;
    links.enable = lib.mkDefault true;

    hyprland.enable = lib.mkDefault true;

    apps = {
      enable = lib.mkDefault true;
      stylix.enable = lib.mkDefault true;
      nvf.enable = lib.mkDefault true;
      terminal.enable = lib.mkDefault true;
    };
  };
}
