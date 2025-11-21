{ ... }:
{
  wayland.windowManager.hyprland = {
    settings.bind = [
      "Super, Escape, exit,"
      "Super, Q, killactive,"

      # move focus
      "Super, H, movefocus, l"
      "Super, J, movefocus, d"
      "Super, K, movefocus, u"
      "Super, L, movefocus, r"

      # swtich workspace
      "Super, 1, workspace, 1"
      "Super, 2, workspace, 2"
      "Super, 3, workspace, 3"
      "Super, 4, workspace, 4"
      "Super, 5, workspace, 5"
      "Super, 6, workspace, 6"
      "Super, 7, workspace, 7"
      "Super, 8, workspace, 8"
      "Super, 9, workspace, 9"
      "Super, 0, workspace, 10"

      # move window to workspace
      "Super Shift, 1, movetoworkspace, 1"
      "Super Shift, 2, movetoworkspace, 2"
      "Super Shift, 3, movetoworkspace, 3"
      "Super Shift, 4, movetoworkspace, 4"
      "Super Shift, 5, movetoworkspace, 5"
      "Super Shift, 6, movetoworkspace, 6"
      "Super Shift, 7, movetoworkspace, 7"
      "Super Shift, 8, movetoworkspace, 8"
      "Super Shift, 9, movetoworkspace, 9"
      "Super Shift, 0, movetoworkspace, 10"

      "Super Control, Return, exec, uwsm app -- rofi -show drun"
      "Super, Return, exec, uwsm app -- kitty"
    ];

    # mouse binds
    bindm = [
      "Super, mouse:272, movewindow"
      "Super, mouse:273, resizewindow"
    ];

    bindel = [
      # ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEAFULT_AUDIO_SINK@ 5%+"
      # ",XF86AudioLowerVolume, exec, wpctl set-volume -l 1 @DEAFULT_AUDIO_SINK@ 5%-"

      ",XF68MonBrightnessUp ,exec, brightnessctl -e4 -n2 set 5%+"
      ",XF68MonBrightnessDown ,exec, brightnessctl -e4 -n2 set 5%-"
    ];
  };
}
