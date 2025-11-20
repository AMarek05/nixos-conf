{ ... }:
{
  programs.waybar.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      exec-once = [
        "uwsm app -- waybar"
      ];
      bind = [
        "Super Control, Return, exec, uwsm app -- rofi -show drun"
        "Super, Return, exec, uwsm app -- kitty"
        "Super, Q, killactive,"
      ];
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
