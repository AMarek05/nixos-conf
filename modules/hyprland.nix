{ inputs, ... }:
{
  imports = [
    ./hyprland/binds.nix
    ./hyprland/decoration.nix
    ./hyprland/windowrules.nix

    ./apps/main.nix

    inputs.walker.homeManagerModules.default
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      exec-once = [
        "uwsm app -- ashell"
      ];
      input = {
        kb_layout = "pl,us";
      };
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
      window_title.truncate_title_after_length = 60;

      appearance = {
        font_name = "JetBrainsMono Nerd Font Propo";
        scale_factor = 1.35;
      };
    };
  };

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      app_launch_prefix = "uwsm app -- ";
      terminal = "ghostty";

      disable_mouse = true;
      close_when_open = true;

      search.placeholder = "Search...";
    };
  };

  programs.rofi = {
    enable = true;

    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
      hide-scrollbar = true;
      sidebar-mode = true;
    };
  };
}
