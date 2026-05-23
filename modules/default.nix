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

    ./apps
    ./caelestia
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
      ghostty.enable = lib.mkDefault true;
      man.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
    };

    shell = {
      zsh.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault false;
    };

    caelestia.enable = lib.mkDefault true;
  };
}
