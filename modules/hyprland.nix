{ ... }:
{
  imports = [
    ./hyprland/binds.nix
    ./hyprland/decoration.nix

    ./apps/main.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      exec-once = [
        "uwsm app -- waybar"
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

  programs.waybar.enable = true;
}
