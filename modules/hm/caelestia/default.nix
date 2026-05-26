# caelestia module — declarative configuration
{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.hmModules.caelestia;

  inputHyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  inputsCaelestia =
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.override
      {
        hyprland = inputHyprland;
        withCli = true;
      };
in
{
  options.hmModules.caelestia = {
    enable = mkEnableOption "Enable caelestia shell module";

    # Direct passthrough to programs.caelestia.settings
    settings = mkOption {
      description = "Caelestia shell configuration";
      default = { };
      type = types.attrsOf types.anything;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.caelestia-shell.inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    programs.caelestia = {
      enable = true;
      package = inputsCaelestia;

      settings = {
        appearance = {
          font = {
            family = {
              clock = "Rubik";
              material = "Material Symbols Rounded";
              mono = "CaskaydiaCove NF";
              sans = "Rubik";
            };
            size.scale = 1;
          };
          padding.scale = 1;
          rounding.scale = 1;
          spacing.scale = 1;
          transparency = {
            base = 0.85;
            enabled = false;
            layers = 0.4;
          };
          anim.durations.scale = 1;
        };

        background = {
          enabled = true;
          wallpaperEnabled = true;
          desktopClock = {
            enabled = false;
            position = "bottom-right";
            scale = 1;
            invertColors = false;
            background = {
              enabled = false;
              blur = true;
              opacity = 0.7;
            };
            shadow = {
              enabled = true;
              blur = 0.4;
              opacity = 0.7;
            };
          };
          visualiser = {
            enabled = false;
            rounding = 1;
            spacing = 1;
            blur = false;
            autoHide = true;
          };
        };

        bar = {
          showOnHover = true;
          activeWindow.showOnHover = true;
          activeWindow.inverted = false;
          activeWindow.compact = false;
          clock.showIcon = true;
          clock.showDate = false;
          clock.background = false;
          dragThreshold = 20;
          persistent = true;
          excludedScreens = [ ];
          scrollActions = {
            workspaces = true;
            volume = true;
            brightness = true;
          };
          workspaces = {
            shown = 5;
            label = " ";
            activeLabel = "󰮯";
            occupiedLabel = "󰮯";
            activeIndicator = true;
            activeTrail = false;
            capitalisation = "preserve";
            maxWindowIcons = 0;
            occupiedBg = false;
            perMonitorWorkspaces = true;
            showWindows = true;
            showWindowsOnSpecialWorkspaces = true;
            specialWorkspaceIcons = [ ];
            windowIcons = [
              {
                regex = "steam(_app_(default|[0-9]+))?";
                icon = "sports_esports";
              }
            ];
          };
          status = {
            showAudio = false;
            showBattery = false;
            showBluetooth = true;
            showKbLayout = true;
            showLockStatus = true;
            showMicrophone = false;
            showNetwork = true;
            showWifi = true;
          };
          tray = {
            background = false;
            compact = false;
            hiddenIcons = [ ];
            iconSubs = [ ];
            recolour = false;
          };
          popouts = {
            activeWindow = true;
            tray = true;
            statusIcons = true;
          };
          entries = [
            {
              id = "logo";
              enabled = true;
            }
            {
              id = "workspaces";
              enabled = true;
            }
            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "activeWindow";
              enabled = true;
            }
            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "tray";
              enabled = true;
            }
            {
              id = "clock";
              enabled = true;
            }
            {
              id = "statusIcons";
              enabled = true;
            }
            {
              id = "power";
              enabled = true;
            }
          ];
        };

        border = {
          rounding = 25;
          thickness = 10;
        };

        dashboard = {
          enabled = true;
          showOnHover = true;
          dragThreshold = 50;
          mediaUpdateInterval = 500;
          resourceUpdateInterval = 1000;
          performance = {
            showBattery = true;
            showCpu = true;
            showGpu = true;
            showMemory = true;
            showNetwork = true;
            showStorage = true;
          };
        };

        general = {
          logo = "";
          apps = {
            explorer = [ "nautilus" ];
            playback = [ "mpv" ];
            audio = [ "pavucontrol" ];
          };
          battery = {
            criticalLevel = 3;
            warnLevels = [
              {
                level = 20;
                icon = "battery_android_frame_2";
                title = "Low battery";
                message = "You might want to plug in a charger";
              }
              {
                level = 10;
                icon = "battery_android_frame_1";
                title = "Did you see the previous message?";
                message = "You should probably plug in a charger <b>now</b>";
              }
              {
                level = 5;
                icon = "battery_android_alert";
                title = "Critical battery level";
                message = "PLUG THE CHARGER RIGHT NOW!!";
                critical = true;
              }
            ];
          };
          idle = {
            inhibitWhenAudio = true;
            lockBeforeSleep = true;
            timeouts = [
              {
                timeout = 300;
                idleAction = "lock";
              }
              {
                timeout = 330;
                idleAction = "dpms off";
                returnAction = "dpms on";
              }
              {
                timeout = 600;
                idleAction = [
                  "systemctl"
                  "suspend-then-hibernate"
                ];
              }
            ];
          };
        };

        launcher = {
          enabled = true;
          showOnHover = false;
          dragThreshold = 50;
          actionPrefix = ">";
          specialPrefix = "@";
          maxShown = 7;
          maxWallpapers = 9;
          enableDangerousActions = false;
          vimKeybinds = false;
          useFuzzy = {
            apps = false;
            actions = false;
            schemes = false;
            variants = false;
            wallpapers = false;
          };
          hiddenApps = [
            "nm-connection-editor"
            "vim"
            "syncthing-ui"
            "nvim"
            "cups"
            "alacarte"
            "gvim"
            "btop"
            "qt6ct"
            "qt5ct"
            "kvantummanager"
          ];
          favouriteApps = [ ];
          actions = [
            {
              name = "Calculator";
              description = "Do simple math equations (powered by Qalc)";
              icon = "calculate";
              command = [
                "autocomplete"
                "calc"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Scheme";
              description = "Change the current colour scheme";
              icon = "palette";
              command = [
                "autocomplete"
                "scheme"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Wallpaper";
              description = "Change the current wallpaper";
              icon = "image";
              command = [
                "autocomplete"
                "wallpaper"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Variant";
              description = "Change the current scheme variant";
              icon = "colors";
              command = [
                "autocomplete"
                "variant"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Transparency";
              description = "Change shell transparency";
              icon = "opacity";
              command = [
                "autocomplete"
                "transparency"
              ];
              dangerous = false;
              enabled = false;
            }
            {
              name = "Random";
              description = "Switch to a random wallpaper";
              icon = "casino";
              command = [
                "caelestia"
                "wallpaper"
                "-r"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Light";
              description = "Change the scheme to light mode";
              icon = "light_mode";
              command = [
                "setMode"
                "light"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Dark";
              description = "Change the scheme to dark mode";
              icon = "dark_mode";
              command = [
                "setMode"
                "dark"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Shutdown";
              description = "Shutdown the system";
              icon = "power_settings_new";
              command = [
                "systemctl"
                "poweroff"
              ];
              dangerous = true;
              enabled = true;
            }
            {
              name = "Reboot";
              description = "Reboot the system";
              icon = "cached";
              command = [
                "systemctl"
                "reboot"
              ];
              dangerous = true;
              enabled = true;
            }
            {
              name = "Logout";
              description = "Log out of the current session";
              icon = "exit_to_app";
              command = [
                "loginctl"
                "terminate-user"
                ""
              ];
              dangerous = true;
              enabled = true;
            }
            {
              name = "Lock";
              description = "Lock the current session";
              icon = "lock";
              command = [
                "loginctl"
                "lock-session"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Sleep";
              description = "Suspend then hibernate";
              icon = "bedtime";
              command = [
                "systemctl"
                "suspend-then-hibernate"
              ];
              dangerous = false;
              enabled = true;
            }
            {
              name = "Settings";
              description = "Configure the shell";
              icon = "settings";
              command = [
                "caelestia"
                "shell"
                "controlCenter"
                "open"
              ];
              dangerous = false;
              enabled = true;
            }
          ];
        };

        lock = {
          enableFprint = true;
          hideNotifs = false;
          maxFprintTries = 3;
          recolourLogo = false;
        };

        notifs = {
          expire = true;
          actionOnClick = false;
          clearThreshold = 0.3;
          defaultExpireTimeout = 5000;
          expandThreshold = 20;
          openExpanded = false;
          fullscreen = "on";
          groupPreviewNum = 3;
        };

        osd = {
          enabled = true;
          enableBrightness = true;
          enableMicrophone = false;
          hideDelay = 2000;
        };

        paths = {
          lockNoNotifsPic = "root:/assets/dino.png";
          noNotifsPic = "root:/assets/dino.png";
          sessionGif = "root:/assets/kurukuru.gif";
          mediaGif = "root:/assets/bongocat.gif";
          wallpaperDir = "/home/adam/Pictures/Wallpapers";
          lyricsDir = "/home/adam/Music/lyrics/";
        };

        services = {
          audioIncrement = 0.1;
          brightnessIncrement = 0.1;
          defaultPlayer = "Spotify";
          maxVolume = 1;
          gpuType = "";
          useFahrenheit = false;
          useFahrenheitPerformance = false;
          useTwelveHourClock = false;
          showLyrics = false;
          lyricsBackend = "Auto";
          visualiserBars = 45;
          smartScheme = true;
          weatherLocation = "";
          playerAliases = [
            {
              from = "com.github.th_ch.youtube_music";
              to = "YT Music";
            }
          ];
        };

        session = {
          enabled = true;
          dragThreshold = 30;
          vimKeybinds = false;
          commands = {
            hibernate = [
              "systemctl"
              "hibernate"
            ];
            logout = [
              "loginctl"
              "terminate-user"
              ""
            ];
            reboot = [
              "systemctl"
              "reboot"
            ];
            shutdown = [
              "systemctl"
              "poweroff"
            ];
          };

          icons = {
            hibernate = "downloading";
            logout = "logout";
            reboot = "cached";
            shutdown = "power_settings_new";
          };
        };

        sidebar = {
          enabled = true;
          dragThreshold = 80;
        };

        utilities = {
          enabled = true;
          maxToasts = 4;
          quickToggles = [
            {
              id = "wifi";
              enabled = true;
            }
            {
              id = "bluetooth";
              enabled = true;
            }
            {
              id = "mic";
              enabled = true;
            }
            {
              id = "settings";
              enabled = true;
            }
            {
              id = "gameMode";
              enabled = true;
            }
            {
              id = "dnd";
              enabled = true;
            }
            {
              id = "vpn";
              enabled = false;
            }
          ];

          toasts = {
            audioInputChanged = true;
            audioOutputChanged = true;
            capsLockChanged = true;
            chargingChanged = true;
            configLoaded = true;
            dndChanged = true;
            fullscreen = "off";
            gameModeChanged = true;
            kbLayoutChanged = true;
            nowPlaying = false;
            numLockChanged = true;
            vpnChanged = true;
          };

          vpn = {
            enabled = false;
            provider = [ ];
          };
        };
      }
      // cfg.settings;
    };
  };
}
