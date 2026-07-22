{
  lib,
  config,
  myLib,
  ...
}:
let
  # import lua parser
  inherit (myLib) toLua;

  cfg = config.hmModules.hyprland.animations;

  renderCurve =
    name: points: "hl.curve(${toLua name}, { type = \"bezier\", points = ${toLua points} })";

  renderAnim = anim: "hl.animation(${toLua anim})";
in
{
  options.hmModules.hyprland.animations = {
    enable = lib.mkEnableOption "animations";

    curves = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.float);
      default = { };
    };

    settings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Declarative definition:
    hmModules.hyprland.animations = {
      curves = {
        easeInOut = [
          0.4
          0.0
          0.2
          1.0
        ];
      };
      settings = [
        {
          leaf = "workspaces";
          enabled = true;
          speed = 1.5;
          curve = "easeInOut";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 2.0;
          curve = "easeInOut";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 1.5;
          curve = "easeInOut";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 1.5;
          curve = "easeInOut";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 2.0;
          curve = "easeInOut";
        }
      ];
    };

    wayland.windowManager.hyprland.extraLuaFiles."animations" = ''
      -- onStart: curves
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderCurve cfg.curves)}

      -- onStart: animations
      ${lib.concatMapStringsSep "\n" renderAnim cfg.settings}
    '';
  };
}
