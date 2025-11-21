{ pkgs, ... }:
{
  imports = [
    ./terminal.nix
  ];

  home.packages = with pkgs; [
    heroic
  ];

  gtk = {
    enable = true;
    colorScheme = "dark";
  };

  programs.firefox.enable = true;
}
