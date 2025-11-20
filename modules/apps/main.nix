{ pkgs, ... }:
{
  home.packages = with pkgs; [
    heroic
  ];

  programs.firefox.enable = true;
}
