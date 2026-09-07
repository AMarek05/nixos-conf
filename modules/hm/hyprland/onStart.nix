# Hyprland 0.56+ onStart wrapper.
#
# Background: hyprlang is deprecated and Hyprland 0.56+ reads `hyprland.lua`,
# where each setting is a function call on the global `hl` table. The old
# `exec-once = [ "..." ]` attrset doesn't survive the conversion because
# hyprland has no `hl.exec_once` API — autostart now goes through
# `hl.on("hyprland.start", function () hl.exec_cmd("...") end)`.
#
# This module exposes a **declarative** attrset (`hmModules.hyprland.onStart`)
# that gets translated into the proper Lua start-hook and written to
# `~/.config/hypr/on-start.lua` via `extraLuaFiles`. The generated main
# `hyprland.lua` does `require("on-start")`, so the commands fire once at
# hyprland startup.
#
# Override semantics follow standard Nix:
#   - `onStart.commands` is a list of strings or packages; modules can append
#     freely. Use `lib.mkForce` to replace the whole list.
#   - Cmd strings support `\n` and `\\` `\"` escapes; derivation entries are
#     resolved to `${drv}/bin/${pname}` so a Nix package can be added without
#     knowing the exact binary path.
#   - `pre` and `post` are rendered as separate `hl.on("hyprland.start", ...)`
#     blocks so that higher-priority dependencies (dbus, systemd --user) run
#     before the main commands, and post-start things (wallpaper restoration)
#     run after.
{
  lib,
  config,
  ...
}:
let
  cfg = config.hmModules.hyprland.onStart;

  # Lua-encode a string. Lua's short string literals are C-ish, so we reuse
  # the same escape table as JSON for the characters we care about.
  luaQuote =
    s:
    let
      escaped = lib.replaceStrings [ "\\" "\"" "\n" "\r" "\t" ] [ "\\\\" "\\\"" "\\n" "\\r" "\\t" ] s;
    in
    "\"${escaped}\"";

  # Resolve a command entry to a runnable shell string.
  resolveCmd = c: if lib.isDerivation c then "${c}/bin/${c.pname or c.name}" else c;

  # Render a command line. The heredoc lives on a single line so Nix's
  # anti-indent rule (\"\"\"...\"\"\") is not an issue.
  cmdLine = c: "hl.exec_cmd(${luaQuote (resolveCmd c)})";

  # Render a list of commands, one per line, each indented with two spaces.
  # We use `replaceStrings` to add the indent after joining — this avoids
  # the heredoc anti-indent trap while keeping the call sites readable.
  renderCmds =
    cmds:
    let
      joined = lib.concatMapStringsSep "\n" cmdLine cmds;
    in
    if joined == "" then "" else lib.replaceStrings [ "\n" ] [ "\n  " ] joined;

  # Render a labelled group of commands as an `hl.on(\"hyprland.start\", ...)`
  # block. The `${renderCmds cmds}` insertion is also on a single line, so
  # the lambda body's indent (`  `) is preserved by heredoc anti-indent.
  renderList =
    label: cmds:
    if cmds == [ ] then
      ""
    else
      ''
        -- onStart: ${label}
        hl.on("hyprland.start", function ()
          ${renderCmds cmds}
        end)
      '';

  rendered = lib.concatStrings [
    (renderList "pre" cfg.pre)
    (renderList "commands" cfg.commands)
    (renderList "post" cfg.post)
  ];
in
{
  options.hmModules.hyprland.onStart = {
    commands = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [ ];
      example = lib.literalExpression ''
        [
          pkgs.polkit_gnome
          "firefox"
        ]
      '';
      description = ''
        Commands to run on Hyprland startup. Each entry is rendered as
        a `hl.exec_cmd(\"...\")` call inside an `hl.on(\"hyprland.start\", ...)`
        block in the generated Lua config.

        Entries may be:
          - a string: emitted verbatim
          - a derivation: resolved to its `/bin/<pname>` path so a Nix package
            can be added without knowing the exact binary path.
      '';
    };

    pre = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [ ];
      example = [ "dbus-update-activation-environment --systemd --all" ];
      description = ''
        Commands to run before `commands`. Use for environment setup
        (dbus, systemd --user, etc.) that other commands depend on.

        Rendered as a separate `hl.on(\"hyprland.start\", ...)` block placed
        before `commands`.
      '';
    };

    post = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [ ];
      example = [ "waypaper --restore" ];
      description = ''
        Commands to run after `commands`. Use for wallpaper / wallpaper
        restoration and other things that depend on the session being up.

        Rendered as a separate `hl.on(\"hyprland.start\", ...)` block placed
        after `commands`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.extraLuaFiles = {
      "on-start" = rendered;
    };
  };
}
