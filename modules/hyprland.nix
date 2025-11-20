{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      "$mainMod" = "SUPER";
      exec-once = [
        "uwsm finalize"
      ];

      bind = [
        "SUPER_CTRL, Enter, exec, uwsm app -- rofi -show drun"
        "SUPER, Enter, exec, uwsm app -- kitty"
      ];
    };
  };
  programs.waybar.systemd.enable = true;
  services.dunst.enable = true;
  # services.swww.enable = true;

  programs.rofi = {
    enable = true;

    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
      hide-scrollbar = true;
      sudebar-mode = true;
    };
  };
}
