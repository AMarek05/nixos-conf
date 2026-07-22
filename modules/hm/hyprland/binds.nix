{
  lib,
  config,
  myLib,
  ...
}:
let
  mod = "Super";
  cfg = config.hmModules.hyprland.binds;

  inherit (myLib) toLua;

  renderBind =
    b:
    let
      flagsStr = if b.flags == { } then "" else ", ${toLua b.flags}";
    in
    "hl.bind(${toLua b.mods}, ${toLua b.key}, ${b.action}${flagsStr})";
in
{
  options.hmModules.hyprland.binds = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          mods = lib.mkOption {
            type = lib.types.str;
            default = "";
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
        mods = mod;
        key = "Escape";
        action = "hl.dsp.exit()";
      }
      {
        mods = mod;
        key = "Q";
        action = "hl.dsp.window.close()";
      }

      # caelestia
      {
        mods = mod;
        key = "Escape";
        action = "hl.dsp.global(\"caelestia:powermenu\")";
      }
      {
        mods = mod;
        key = "L";
        action = "hl.dsp.global(\"caelestia:lock\")";
      }
      {
        mods = mod;
        key = "Space";
        action = "hl.dsp.global(\"caelestia:launcher\")";
      }

      # session
      {
        mods = "${mod} Shift";
        key = "L";
        action = "hl.dsp.exec_cmd(\"systemctl suspend\")";
      }

      # window
      {
        mods = mod;
        key = "M";
        action = "hl.dsp.fullscreen(1)";
      }
      {
        mods = mod;
        key = "F";
        action = "hl.dsp.fullscreen(0)";
      }
      {
        mods = "${mod} Shift";
        key = "Space";
        action = "hl.dsp.window.float({ action = \"toggle\" })";
      }

      # apps
      {
        mods = mod;
        key = "Return";
        action = "hl.dsp.exec_cmd(\"ghostty -e tmux new-session -A -s main\")";
      }
      {
        mods = mod;
        key = "B";
        action = "hl.dsp.exec_cmd(\"zen-beta\")";
      }

      # screenshot
      {
        mods = "Ctrl";
        key = "Print";
        action = "hl.dsp.exec_cmd(\"grimblast copy active\")";
      }
      {
        key = "Print";
        action = "hl.dsp.exec_cmd(\"grimblast --freeze copy area\")";
      }

      # move focus
      {
        mods = mod;
        key = "H";
        action = "hl.dsp.movefocus(\"l\")";
      }
      {
        mods = mod;
        key = "J";
        action = "hl.dsp.movefocus(\"d\")";
      }
      {
        mods = mod;
        key = "K";
        action = "hl.dsp.movefocus(\"u\")";
      }
      {
        mods = mod;
        key = "L";
        action = "hl.dsp.movefocus(\"r\")";
      }

      # mouse binds
      {
        mods = mod;
        key = "mouse:272";
        action = "hl.dsp.window.drag()";
        flags = {
          mouse = true;
        };
      }
      {
        mods = mod;
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
        key = "XF86AudioRaiseVolume";
        action = "hl.dsp.exec_cmd(\"wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+\")";
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
              mods = mod;
              key = key;
              action = "hl.dsp.workspace(\"${ws}\")";
            }
            {
              mods = "${mod} Shift";
              key = key;
              action = "hl.dsp.movetoworkspace(\"${ws}\")";
            }
          ]
        ) 10
      ));

    wayland.windowManager.hyprland.extraLuaFiles."binds" = lib.concatMapStringsSep "\n" renderBind cfg;
  };
}
