# modules/custom/modules.nix
# Shared module library for modules/nixos/ and modules/hm/.
#
# Each entry drives:
#   1. The `imports = [ ... ]` list:
#      - Resolves `name.nix` or `name/default.nix` automatically from disk.
#      - Lone directories with only `default.nix` need no special flags.
#      - For directories with `sub` entries, recursively imports every
#        nested sibling and any existing `default.nix` along the path.
#   2. The `options` declarations for <namespace>.<name>[.<sub>...].enable
#      recursively to arbitrary depth.
#
# Entry Shorthand:
#   Plain strings are supported for simple modules without custom flags:
#     entries = [ "git" "fish" { name = "desktop"; sub = [ "audio" "wayland" ]; } ];
#
# Enable semantics:
#   optional = true         → enable default false
#   optional = false/absent → enable default true
#
# Option flags:
#   createOption (default: true): Emits typed enable options for the entry.
#   Set to false when an entry defines a richer option surface manually
#   in its own file (e.g. settings submodules).
#
# Atomicity (parent-off cascades to children):
#   Enforce parent-to-child cascading at consumer sites using the exported
#   `isEnabled` helper:
#     lib.mkIf (lib.my.isEnabled config "nixosModules" "desktop.wm.hyprland") { ... }
#
# Usage:
#   lib.my.mkHostModules {
#     namespace = "nixosModules";
#     basePath  = ../../modules/nixos;
#     entries   = [
#       "sound"       # auto-resolves to sound.nix or sound/default.nix
#       "git"
#       {
#         name = "desktop";
#         sub  = [
#           "audio"
#           {
#             name = "wm";
#             sub  = [ "hyprland" "waybar" ];
#           }
#         ];
#       }
#     ];
#   }
{ lib }:

let
  # Normalize entry syntax: allows string shorthand "foo" -> { name = "foo"; }
  normalizeEntry = e: if builtins.isString e then { name = e; } else e;

  # Enable semantics: true unless explicitly marked optional
  isEnabledByDefault = e: !(e.optional or false);

  # Imports resolution
  mkEntryImports =
    basePath: rawEntry:
    let
      e = normalizeEntry rawEntry;
      dirPath = basePath + "/${e.name}";
      filePath = basePath + "/${e.name}.nix";
      defaultNix = dirPath + "/default.nix";

      # An entry is treated as a directory if:
      #   - explicitly tagged with kind = "dir"
      #   - declares sub-entries
      #   - no <name>.nix exists, but <name>/default.nix exists on disk
      isDirEntry =
        (e.kind or null) == "dir"
        || (e ? sub)
        || ((e.kind or null) != "file" && !builtins.pathExists filePath && builtins.pathExists defaultNix);
    in
    if isDirEntry then
      let
        hasDefault = builtins.pathExists defaultNix;
        subImports = lib.optionals (e ? sub) (lib.concatMap (mkEntryImports dirPath) e.sub);
      in
      lib.optional hasDefault defaultNix ++ subImports
    else
      [ filePath ];

  mkImports = basePath: entries: lib.concatMap (mkEntryImports basePath) entries;

  # Options generation
  mkEntryOptions =
    pathPrefix: rawEntry:
    let
      e = normalizeEntry rawEntry;
      currentPath = pathPrefix ++ [ e.name ];
      pathStr = lib.concatStringsSep "." currentPath;

      # Emit typed enable option unless explicitly opted out
      nodeOption = lib.optionalAttrs (e.createOption or true) {
        enable = lib.mkEnableOption pathStr // {
          default = isEnabledByDefault e;
        };
      };

      # Recursively declare options for any sub-entries
      subOptions =
        if e ? sub then
          lib.foldl' lib.recursiveUpdate { } (map (mkEntryOptions currentPath) e.sub)
        else
          { };

      combined = nodeOption // subOptions;
    in
    lib.optionalAttrs (combined != { }) {
      ${e.name} = combined;
    };

  mkOptions = ns: entries: {
    ${ns} = lib.foldl' lib.recursiveUpdate { } (map (mkEntryOptions [ ]) entries);
  };

  # Cascading enable helper.
  # Verifies that every level along the path is enabled in `config.<ns>`.
  # Accepts either dot-notation ("desktop.audio") or a list (["desktop" "audio"]).
  # If any intermediate level lacks an `enable` option (e.g. grouping container),
  # it passes through to the next level.
  # Throws if any segment along the path does not exist in `config.<ns>`.
  isEnabled =
    config: ns: path:
    let
      parts =
        if builtins.isList path then
          lib.concatMap (x: lib.splitString "." x) path
        else
          lib.splitString "." path;
      pathStr = if builtins.isString path then path else lib.concatStringsSep "." path;
      prefixes = lib.genList (i: lib.take (i + 1) parts) (builtins.length parts);
      checkPrefix =
        prefix:
        let
          fullPath = [ ns ] ++ prefix;
        in
        if !lib.hasAttrByPath fullPath config then
          throw "lib.my.isEnabled: unknown module path '${ns}.${pathStr}' (segment '${lib.concatStringsSep "." prefix}' does not exist)"
        else
          let
            node = lib.attrByPath fullPath null config;
          in
          if node ? enable then node.enable else true;
    in
    builtins.all checkPrefix prefixes;

in
{
  inherit isEnabled;

  mkHostModules =
    {
      namespace,
      basePath,
      entries,
    }:
    {
      imports = mkImports basePath entries;
      options = mkOptions namespace entries;
    };
}
