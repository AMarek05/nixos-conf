{ inputs, pkgs, ... }:
{
  imports = [
    ./terminal.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.packages = with pkgs; [
    heroic
    keepassxc
  ];

  gtk = {
    enable = true;
    colorScheme = "dark";
  };

  programs.firefox.enable = true;
  programs.zen-browser.enable = true;
}
