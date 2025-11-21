{ inputs, pkgs, ... }:
{
  imports = [
    ./terminal.nix
    inputs.zen-browser.homeModules.twilight-official
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
