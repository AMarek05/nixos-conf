{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = false;

    settings = {
      "$mainMod" = "SUPER";

      bind = [
        "SUPER_CTRL, Enter, exec, rofi -show drun"
        "SUPER, Enter, exec, ghostty"
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
      sidebar-mode = true;
    };
  };
}
