{ ... }:
{
  imports = [
    ../modules/defaults.nix
    ../modules/apps/nvf.nix
  ];

  modules.hyprland.enable = false;
  modules.apps.enable = false;
  modules.apps.stylix.enable = false;

  home.username = "adam";
  home.homeDirectory = "/home/adam";

  programs.home-manager.enable = true;
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
