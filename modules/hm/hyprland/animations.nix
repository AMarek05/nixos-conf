{
  lib,
  config,
  myLib,
  ...
}:
let
  cfg = config.hmModules.hyprland.animations;

  inherit (myLib) toLua;

  renderCurve =
    name: points: "hl.curve(${toLua name}, { type = \"bezier\", points = ${toLua points} })";

  renderAnim =
    anim:
    "hl.animation({ leaf = ${toLua anim.leaf}, enabled = ${toLua anim.enabled}, speed = ${toLua anim.speed}, bezier = ${toLua anim.curve} })";
in
{
  options.hmModules.hyprland.animations = {
    enable = lib.mkEnableOption "animations" // {
      default = true;
    };

    curves = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.listOf lib.types.float));
      default = { };
    };

    settings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Declarative definition matching your exact snappy speeds
    hmModules.hyprland.animations = {
      curves = {
        easeInOut = [
          [
            0.4
            0.0
          ]
          [
            0.2
            1.0
          ]
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

    wayland.windowManager.hyprland.extraConfig = ''
      -- Enable animation engine globally
      hl.config({ animations = { enabled = true } })

      -- Define curves
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderCurve cfg.curves)}

      -- Apply animations
      ${lib.concatMapStringsSep "\n" renderAnim cfg.settings}
    '';
  };
}
