{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class walker, float on"
      "match:class walker, center on"
      "match:class walker, center on"

      "match:class walker, move 0 10%"

      "match:class walker, stay_focused on"
    ];
  };
}
