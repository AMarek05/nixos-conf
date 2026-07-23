{
  lib,
  config,
  myLib,
  ...
}:
let
  mod = "SUPER";
  cfg = config.hmModules.hyprland.binds;

  inherit (myLib) toLua;

  renderBind =
    b:
    let
      keyParts = b.mods ++ [ b.key ];

      keyCombo = lib.concatStringsSep " + " keyParts;

      flagsStr = if b.flags == { } then "" else ", ${toLua b.flags}";
    in
    "hl.bind(${toLua keyCombo}, ${b.action}${flagsStr})";
in
{
  options.hmModules.hyprland.binds = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          mods = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          key = lib.mkOption { type = lib.types.str; };
          action = lib.mkOption { type = lib.types.str; };

          flags = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        };
      }
    );
    default = [ ];
  };

  config = {
    hmModules.hyprland.binds = [
      # main
      {
        mods = [ mod ];
        key = "Escape";
        action = "hl.dsp.exit()";
      }
      {
        mods = [ mod ];
        key = "Q";
        action = "hl.dsp.window.close()";
      }
      {
        mods = [
          mod
          "SHIFT"
        ];
        key = "Q";
        action = "hl.dsp.window.kill()";
      }

      # caelestia
      {
        mods = [ mod ];
        key = "Escape";
        action = "hl.dsp.global(\"caelestia:powermenu\")";
      }
      {
        mods = [ mod ];
        key = "L";
        action = "hl.dsp.global(\"caelestia:lock\")";
      }
      {
        mods = [ mod ];
        key = "Space";
        action = "hl.dsp.global(\"caelestia:launcher\")";
      }

      # session
      {
        mods = [
          mod
          "SHIFT"
        ];
        key = "L";
        action = "hl.dsp.exec_cmd(\"systemctl suspend\")";
      }

      # window
      {
        mods = [ mod ];
        key = "M";
        action = "hl.dsp.window.fullscreen_state({internal = 1, client = -1})";
      }
      {
        mods = [ mod ];
        key = "F";
        action = "hl.dsp.window.fullscreen_state({internal = 2, client = -1})";
      }
      {
        mods = [
          mod
          "SHIFT"
        ];
        key = "F";
        # reset fullscreen state
        action = "hl.dsp.window.fullscreen_state({internal = 0, client = -1})";
      }
      {
        mods = [
          mod
          "SHIFT"
        ];
        key = "Space";
        action = "hl.dsp.window.float({ action = \"toggle\" })";
      }

      # apps
      {
        mods = [ mod ];
        key = "Return";
        action = "hl.dsp.exec_cmd(\"ghostty -e tmux new-session -A -s main\")";
      }
      {
        mods = [ mod ];
        key = "B";
        action = "hl.dsp.exec_cmd(\"zen-beta\")";
      }

      # screenshot
      {
        mods = [ "CTRL" ];
        key = "Print";
        action = "hl.dsp.exec_cmd(\"grimblast copy active\")";
      }
      {
        key = "PRINT";
        action = "hl.dsp.exec_cmd(\"grimblast --freeze copy area\")";
      }

      # move focus
      {
        mods = [ mod ];
        key = "H";
        action = "hl.dsp.focus({ direction = \"l\" })";
      }
      {
        mods = [ mod ];
        key = "J";
        action = "hl.dsp.focus({ direction = \"d\" })";
      }
      {
        mods = [ mod ];
        key = "K";
        action = "hl.dsp.focus({ direction = \"u\" })";
      }
      {
        mods = [ mod ];
        key = "L";
        action = "hl.dsp.focus({ direction = \"r\" })";
      }

      # mouse binds
      {
        mods = [ mod ];
        key = "mouse:272";
        action = "hl.dsp.window.drag()";
        flags = {
          mouse = true;
        };
      }
      {
        mods = [ mod ];
        key = "mouse:273";
        action = "hl.dsp.window.resize()";
        flags = {
          mouse = true;
        };
      }

      # media / binds locked
      {
        key = "XF86AudioMute";
        action = "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")";
        flags = {
          locked = true;
        };
      }
      {
        key = "XF86AudioPlay";
        action = "hl.dsp.exec_cmd(\"playerctl play-pause\")";
        flags = {
          locked = true;
        };
      }
      {
        key = "XF86AudioNext";
        action = "hl.dsp.exec_cmd(\"playerctl next\")";
        flags = {
          locked = true;
        };
      }
      {
        key = "XF86AudioPrev";
        action = "hl.dsp.exec_cmd(\"previous\")";
        flags = {
          locked = true;
        };
      }

      # Audio
      {
        key = "XF86AudioRaiseVolume";
        action = "hl.dsp.exec_cmd(\"wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+\")";
        flags = {
          locked = true;
          repeating = true;
        };
      }
      {
        key = "XF86AudioLowerVolume";
        action = "hl.dsp.exec_cmd(\"wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-\")";
        flags = {
          locked = true;
          repeating = true;
        };
      }

      # Brightness
      {
        key = "XF86MonBrightnessUp";
        action = "hl.dsp.exec_cmd(\"brightnessctl -e4 -n2 set 5%+\")";
        flags = {
          locked = true;
          repeating = true;
        };
      }
      {
        key = "XF86MonBrightnessDown";
        action = "hl.dsp.exec_cmd(\"brightnessctl -e4 -n2 set 5%-\")";
        flags = {
          locked = true;
          repeating = true;
        };
      }
    ]
    ++
      # Generate workspace bindings programmatically
      (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = if i == 9 then "10" else toString (i + 1);
            key = if i == 9 then "0" else toString (i + 1);
          in
          [
            {
              mods = [ mod ];
              key = key;
              action = "hl.dsp.focus({ workspace = \"${ws}\" })";
            }
            {
              mods = [
                mod
                "SHIFT"
              ];
              key = key;
              action = "hl.dsp.window.move({ workspace = \"${ws}\" })";
            }
          ]
        ) 10
      ));

    wayland.windowManager.hyprland.extraConfig = ''
      -- Binds
      ${lib.concatMapStringsSep "\n" renderBind cfg}
    '';
  };
}
