{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./terminal.nix
    ./stylix.nix
    ./nvf.nix

    inputs.zen-browser.homeModules.beta
  ];

  home.packages = with pkgs; [
    heroic
    keepassxc
  ];

  gtk = {
    colorScheme = "dark";
  };

  programs.firefox.enable = true;
  programs.zen-browser.enable = true;
}
