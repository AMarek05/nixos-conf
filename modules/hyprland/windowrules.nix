{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class walker, float"
      "match:class walker, center"
      "match:class walker, center"

      "match:class walker, move 0 10%"

      "match:class walker, stayfocused"
    ];
  };
}
