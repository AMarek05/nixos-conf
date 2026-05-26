{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.hmModules.hyprland;
in
{
  options.hmModules.hyprland = {
    enable = lib.mkEnableOption "Enable the hyprland module";
  };

  imports = [
    ./binds.nix

    ./display.nix
    ./windowrules.nix
    ./animations.nix

    inputs.walker.homeManagerModules.default
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
    home.file."Pictures/Wallpapers" = {
      source = ../../../store/wallpapers;
      recursive = true;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";

      systemd.variables = [ "--all" ];

      package = null;
      portalPackage = null;

      settings = {
        exec-once = [
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];

        env = [
          "XCURSOR_THEME,Bibata-Modern-Classic"
          "XCURSOR_SIZE,24"
        ];

        input = {
          kb_layout = "pl,us";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          background_color = lib.mkForce "rgb(1a1a1a)";
        };
      };
    };
  };
}
