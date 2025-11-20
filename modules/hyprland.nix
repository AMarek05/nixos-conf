{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = false;

    settings = {
      "$mainMod" = "SUPER";

      bind = [
        "SUPER CTRL, Enter, exec, rofi -show drun"
        "SUPER, Enter, exec, kitty"
        "SUPER, M, quit"
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
