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
      match = { title = "OpenGL" },
      float = true,
      center = true
    })

    hl.window_rule({
      match = { class = "^(zen-beta|zen|zen-bin|Navigator|firefox|firefox-developer-edition|chromium|brave-browser)$" },
      suppress_event = "maximize"
    })
  '';
}
