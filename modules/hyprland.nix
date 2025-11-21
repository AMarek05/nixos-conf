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
