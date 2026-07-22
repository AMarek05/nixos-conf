{ ... }:
{
  wayland.windowManager.hyprland.extraLuaFiles."windowrules" = ''
    hl.window_rule({
      match = { class = "walker" },
      float = true,
      center = true,
      move = "0 10%",
      stay_focused = true
    })

    hl.window_rule({
      match = { title = "OpenGL" },
      float = true,
      center = true
    })
  '';
}
