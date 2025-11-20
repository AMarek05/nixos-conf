{ pkgs, ... }:
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
        "SUPER CTRL, Enter, exec, uwsm app -- rofi -show drun"
        "SUPER, Enter, exec, uwsm app -- kitty"
      ];
    };

  };
  # programs.waybar.systemd.enable = true;
  # services.dunst.enable = true;
  # services.swww.enable = true;

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
