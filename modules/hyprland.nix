{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.hyprland;
in
{
  options.modules.hyprland = {
    enable = lib.mkEnableOption "Enable the hyprland module";
    caelestia.enable = lib.mkEnableOption "Enable caelestia shell submodule";
  };

  imports = [
    ./hyprland/binds.nix

    ./hyprland/decoration.nix
    ./hyprland/windowrules.nix

    ./apps/main.nix

    inputs.walker.homeManagerModules.default
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Common hyprland config
      {
        home.file."Pictures/Wallpapers" = {
          source = ../store/wallpapers;
          recursive = true;
        };

        wayland.windowManager.hyprland = {
          enable = true;
          systemd.variables = [ "--all" ];

          package = null;
          portalPackage = null;

          settings = {
            env = [
              "XCURSOR_THEME,Bibata-Modern-Classic"
              "XCURSOR_SIZE,24"
            ];

            general = {
              gaps_in = 5;
              gaps_out = 15;

              border_size = 2;
            };

            input = {
              kb_layout = "pl,us";
            };

            dwindle = {
              preserve_split = true;
              smart_split = false;
              smart_resizing = false;
            };
          };
        };
      }

      (lib.mkIf (!cfg.caelestia.enable)
        # Old config sans caelestia
        {
          wayland.windowManager.hyprland.settings = {
            exec-once = [ "ashell" ];

          };

          services.hypridle = {
            enable = true;
            settings = {
              general = {
                after_sleep_cmd = "hyprctl dispatch dpms on";
                ignore_dbus_inhibit = false;
                lock_cmd = "pidof hyprlock || hyprlock";
                before_sleep_cmd = "loginctl lock-session";
              };

              listener = [
                {
                  timeout = 900;
                  on-timeout = "hyprlock";
                }
                {
                  timeout = 1200;
                  on-timeout = "hyprctl dispatch dpms off";
                  on-resume = "hyprctl dispatch dpms on";
                }
              ];
            };
          };

          programs.hyprlock = {
            enable = true;
            settings = {
              general = {
                no_fade_in = false;
                grace = 0;
                disable_loading_bar = true;
              };

              background = lib.mkForce [
                {
                  blur_passes = 0;
                  blur_size = 4;
                  brightness = 0.5;
                }
              ];

              input-field = lib.mkForce [
                {
                  size = "200, 50";
                  position = "0, -80";
                  monitor = "";
                  dots_center = true;
                  fade_on_empty = false;
                  font_color = "rgb(202, 211, 245)";
                  inner_color = "rgb(91, 96, 120)";
                  outer_color = "rgb(24, 25, 38)";
                  outline_thickness = 5;
                  placeholder_text = "<i>Input Password...</i>";
                  shadow_passes = 2;
                }
              ];

              label = [
                {
                  monitor = "";
                  text = "$TIME";
                  color = "rgb(200, 200, 200)";
                  font_size = 64;
                  font_family = "Noto Sans";
                  position = "0, 160";
                  halign = "center";
                  valign = "center";
                }
              ];
            };
          };

          programs.ashell = {
            enable = true;

            settings = {
              modules = {
                left = [ "WindowTitle" ];
                center = [ "Workspaces" ];
                right = [
                  "SystemInfo"
                  [
                    "Clock"
                    "Privacy"
                  ]
                  "Settings"
                ];
              };

              workspaces.enable_workspace_filling = true;
              workspaces.max_workspaces = 5;

              window_title.mode = "Title";
              window_title.truncate_title_after_length = 50;

              appearance = {
                font_name = "JetBrainsMono Nerd Font Propo";
                scale_factor = 1.20;
              };
            };
          };

          programs.walker = {
            enable = true;
            runAsService = true;

            config = {
              terminal = "ghostty";

              disable_mouse = true;
              close_when_open = true;

              search.placeholder = "Search...";
            };
          };
        }
      )

      (lib.mkIf cfg.caelestia.enable {
        programs.caelestia = {
          enable = true;
          systemd.enable = true;

          cli.enable = true;
        };
      })
    ]
  );

}
