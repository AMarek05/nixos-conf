# lib/modules.nix
# Shared module library for modules/nixos/ and modules/hm/.
#
# Each entry drives:
#   1. The `imports = [ ... ]` list (./name.nix or ./name/)
#   2. The `options` declarations for <namespace>.<name>[/<sub>].enable
#
# For dir entries with sub-entries, the catalog auto-imports each sibling
# alongside default.nix — so the directory's default.nix has zero import
# Third-party inputs the directory needs are imported directly in the
# directory's own file(s) (e.g. inputs.X.homeModules in someFile.nix).
#
# Enable semantics:
#   optional = true         → enable default false
#   optional = false/absent → enable default true
#
# createOption (default: true): lib emits typed enable options for the
# entry. Set to false when the entry has a richer option surface than
# enable alone (e.g. caelestia with settings); the file then declares
# its own options.
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
          # Only import default.nix if it actually exists on disk.
          # An empty/default.nix that does nothing is a no-op placeholder
          # and should be deleted rather than kept around.
          (if builtins.pathExists (dirPath + "/default.nix")
           then [ (dirPath + "/default.nix") ]
           else [ ])
          ++ lib.optionals (e ? sub) (
            # Build a flat list of imports for one entry: own default.nix
            # + each sub (or each sub's children if the sub is itself a
            # nested grouping).
            let
              perSub = sub:
                if sub ? sub then
                  # A sub-entry with its own sub is a grouping label.
                  # Import its directory's default.nix + each sibling.
                  [
                    (dirPath + "/${sub.name}/default.nix")
                  ] ++ map (ss:
                    dirPath + "/${sub.name}/${ss.name}.nix"
                  ) sub.sub
                else
                  [ (dirPath + "/${sub.name}.nix") ];
            in
            lib.concatMap perSub e.sub
          )
        else
          [ (basePath + "/${e.name}.nix") ];
    in
    baseImports;

  mkImports =
    basePath: entries:
    lib.concatLists (map (mkEntryImports basePath) entries);

  # An entry is enabled-by-default unless explicitly marked optional.
  isEnabledByDefault =
    e:
    !(e.optional or false);

  # One entry's contribution to options.<ns>.
  # createOption = true (default): lib emits typed enable option + per-sub.
  # createOption = false: caller file declares its own options (escape
  # hatch for entries like caelestia with a richer option surface).
  buildEntryOptions =
    e:
    if e.createOption or true then
      let
        parentEnable = {
          enable = lib.mkEnableOption "${e.name} module" // {
            default = isEnabledByDefault e;
          };
        };

        buildSubEnable =
          sub:
          let
            subDefault = isEnabledByDefault sub;
            subCreateOption = sub.createOption or true;
            childEnable = if subCreateOption then {
              enable = lib.mkEnableOption "${e.name}.${sub.name}" // {
                default = subDefault;
              };
            } else { };
            grandchildren =
              if sub ? sub then
                lib.foldl' (acc: ss: acc // { ${ss.name}.enable = lib.mkEnableOption "${e.name}.${sub.name}.${ss.name}" // { default = isEnabledByDefault ss; }; }) { } sub.sub
              else { };
          in
          { ${sub.name} = childEnable // grandchildren; };

        subEnables =
          if e.kind == "dir" && e ? sub then
            lib.foldl' (acc: sub: acc // buildSubEnable sub) { } e.sub
          else
            { };
      in
      { ${e.name} = parentEnable // subEnables; }
    else
      { };

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
