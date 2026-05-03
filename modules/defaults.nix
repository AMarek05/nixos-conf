{ lib, ... }:
{
  imports = [
    ./git.nix
    ./util.nix
    ./env.nix
    ./links.nix

    ./terminal
    ./shell
    ./hyprland

    ./apps/main.nix
    ./apps/nvf.nix
    ./apps/stylix.nix
  ];

  modules = {
    env.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    util.enable = lib.mkDefault true;
    links.enable = lib.mkDefault true;

    hyprland.enable = lib.mkDefault true;
    hyprland.caelestia.enable = lib.mkDefault true;

    apps = {
      enable = lib.mkDefault true;
      stylix.enable = lib.mkDefault true;
      nvf.enable = lib.mkDefault true;
    };

    terminal = {
      enable = lib.mkDefault true;
      less.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      ghostty.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
    };

    shell = {
      enable = lib.mkDefault true;
    };
  };
}
