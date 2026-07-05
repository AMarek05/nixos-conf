# lib/modules.nix
# Shared module library for modules/nixos/ and modules/hm/.
#
# Each entry drives:
#   1. The `imports = [ ... ]` list (./name.nix or ./name/)
#   2. The `options` declarations for <namespace>.<name>[/<sub>].enable
#
# For dir entries with sub-entries, the catalog auto-imports each sibling
# alongside default.nix — so the directory's default.nix has zero import
# bookkeeping if it wants. Third-party inputs (e.g. inputs.X.homeModules)
# the directory still needs can be added with the `extraImports` field.
#
# Enable semantics:
#   optional = true         → enable default false
#   optional = false/absent → enable default true
#
# Atomicity (parent-off cascades to subs) is enforced at consumer sites
# via lib.mkIf (config.<ns>.<parent>.enable && config.<ns>.<parent>.<sub>.enable).
#
# Usage:
#   let modulesLib = import ../../lib/modules.nix { inherit lib; };
#   in modulesLib.mkHostModules {
#     namespace = "nixosModules";
#     basePath  = ../../modules/nixos;
#     entries   = [ ... ];
#   }
{ lib }:

let
  # Build the `imports` list for one entry.
  # For dir-with-sub: returns default.nix + each sibling.
  mkEntryImports =
    basePath: e:
    let
      dirPath = basePath + "/${e.name}";
      baseImports =
        if e.kind == "dir" then
          [ (dirPath + "/default.nix") ]
          ++ (lib.optionals (e ? sub) (
            map (sub: dirPath + "/${sub.name}.nix") e.sub
          ))
        else
          [ (basePath + "/${e.name}.nix") ];
    in
    baseImports ++ (e.extraImports or [ ]);

  mkImports =
    basePath: entries:
    lib.concatMap (mkEntryImports basePath) entries;

  # An entry is enabled-by-default unless explicitly marked optional.
  isEnabledByDefault =
    e:
    !(e.optional or false);

  # One entry's contribution to options.<ns>.
  # When optionsOwnedByFile = true, the file declares its own options
  # (escape hatch for entries like caelestia that have a richer option
  # surface than enable alone). Otherwise: emit parent enable + per-sub
  # enable for dir-with-sub.
  buildEntryOptions =
    e:
    if e.optionsOwnedByFile or false then
      { }
    else
      let
        parentEnable = {
          enable = lib.mkEnableOption "${e.name} module" // {
            default = isEnabledByDefault e;
          };
        };

        subEnables =
          if e.kind == "dir" && e ? sub then
            lib.foldl' (
              acc: sub:
              let
                subDefault = isEnabledByDefault sub;
              in
              acc
              // {
                ${sub.name}.enable = lib.mkEnableOption "${e.name}.${sub.name} (tracks parent unless overridden)" // {
                  default = subDefault;
                };
              }
            ) { } e.sub
          else
            { };
      in
      {
        ${e.name} = parentEnable // subEnables;
      };

  mkOptions =
    ns: entries:
    { ${ns} = lib.foldl' (acc: e: acc // buildEntryOptions e) { } entries; };
in

{
  mkHostModules =
    { namespace, basePath, entries }:
    {
      imports = mkImports basePath entries;
      options = mkOptions namespace entries;
    };
}
