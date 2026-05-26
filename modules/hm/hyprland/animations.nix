{ ... }:
{
  wayland.windowManager.hyprland.settings.animations = {
    enabled = true;

    # Bezier curves must be a list of comma-separated strings
    # Format: NAME, X0, Y0, X1, Y1
    bezier = [
      "easeInOut, 0.4, 0, 0.2, 1"
    ];

    # Animations must be a list of comma-separated strings
    # Format: NAME, ONOFF, SPEED, CURVE
    # Note: SPEED is in 100ms units. (e.g., 1.5 = 150ms, 2 = 200ms)
    animation = [
      "workspaces, 1, 1.5, easeInOut"
      "windows, 1, 2, easeInOut"
      "windowsIn, 1, 1.5, easeInOut" # Hyprland uses 'windowsIn' for window open
      "windowsOut, 1, 1.5, easeInOut" # Hyprland uses 'windowsOut' for window close
      "layers, 1, 2, easeInOut"
    ];
  };
}
