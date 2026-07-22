{
  inputs,
  lib,
  config,
  pkgs,
  myLib,
  ...
}:
let
  cfg = config.hmModules.hyprland;

  inherit (myLib) toLua;
  inherit (lib)
    mkOption
    types
    mapAttrsToList
    concatStringsSep
    mkForce
    ;
in
{
  imports = [
    ./binds.nix

    ./display.nix
    ./windowrules.nix
    ./animations.nix

    inputs.walker.homeManagerModules.default
    inputs.caelestia-shell.homeManagerModules.default
  ];

  options.hmModules.hyprland = {
    env = mkOption {
      type = types.attrsOf (types.either types.str types.int);
      default = { };
      description = "Environment variables to pass to hl.env()";
    };

    settings = mkOption {
      type = types.typesOf types.attrs;
      default = { };
      description = "Hyprland config passed to hl.config()";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file."Pictures/Wallpapers" = {
      source = ../../../store/wallpapers;
      recursive = true;
    };

    hmModules.hyprland = {
      settings = {
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

      env = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = 24;
      };

      onStart.commands = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";

      systemd.variables = [ "--all" ];

      package = null;
      portalPackage = null;

      extraConfig = ''
        -- Core settings
        hl.config(${toLua cfg.setting})

        -- Environment variables
        ${concatStringsSep "\n" (
          mapAttrsToList (k: v: "hl.env(${toLua k}, ${toLua (toString v)})") cfg.env
        )}
      '';
    };
  };
}
