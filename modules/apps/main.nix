{ pkgs, ... }:
{
  imports = [
    ./terminal.nix
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
}
