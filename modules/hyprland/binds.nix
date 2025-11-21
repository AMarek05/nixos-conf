{ ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      "$mod" = "Super";
      bind = [
        "$mod, Escape, exit,"
        "$mod, Q, killactive,"

        # apps
        "$mod Control, Return, exec, uwsm app -- rofi -show drun"
        "$mod, Return, exec, uwsm app -- ghostty"

        # move focus
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"

        # swtich workspace
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # move window to workspace
        "$mod Shift, 1, movetoworkspace, 1"
        "$mod Shift, 2, movetoworkspace, 2"
        "$mod Shift, 3, movetoworkspace, 3"
        "$mod Shift, 4, movetoworkspace, 4"
        "$mod Shift, 5, movetoworkspace, 5"
        "$mod Shift, 6, movetoworkspace, 6"
        "$mod Shift, 7, movetoworkspace, 7"
        "$mod Shift, 8, movetoworkspace, 8"
        "$mod Shift, 9, movetoworkspace, 9"
        "$mod Shift, 0, movetoworkspace, 10"
      ];

      # mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-"

        ",XF86MonBrightnessUp ,exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown ,exec, brightnessctl -e4 -n2 set 5%-"
      ];
    };
  };
}
