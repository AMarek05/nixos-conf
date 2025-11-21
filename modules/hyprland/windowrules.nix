{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float, class:(walker)"
      "center, class:(walker)"
      "size 600 500, class:(walker)"

      "move 0 10%, class:(walker)"

      "stayfocused, class:(walker)"
    ];
  };
}
