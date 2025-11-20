{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      exec-once = [
        "uwsm finalize"
      ];

      bind = [
        "$mainMod, A, exec, uwsm app -- rofi -show drun"
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
