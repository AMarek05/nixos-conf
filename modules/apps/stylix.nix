{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  options.modules.apps.stylix = {
    enable = lib.mkEnableOption "stylix";
  };

  config = lib.mkIf config.modules.apps.stylix.enable {
    gtk.gtk4.theme = lib.mkForce null;

    stylix = {
      enable = true;

      enableReleaseChecks = false;

      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

      polarity = "dark";

      # Change to match about:profiles
      targets.zen-browser.profileNames = [ "adam" ];

      targets.gtk.enable = true;
      targets.gnome.enable = true;
      targets.qt.enable = true;

      targets.starship.enable = false;
      targets.firefox.enable = false;

      targets.ghostty.enable = false;
      targets.tmux.enable = false;

      targets.nvf.transparentBackground = true;

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      icons = {
        enable = true;
        package = pkgs.dracula-icon-theme;
        dark = "Dracula";
        light = "Dracula";
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
      };
    };
  };
}
