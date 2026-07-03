# lib/modules.nix
# Shared module library for modules/nixos/ and modules/hm/.
#
# Each entry drives:
#   1. The `imports = [ ... ]` list (./name.nix or ./name/)
#   2. The `options` declarations for <namespace>.<name>[/<sub>].enable
#
# Enable semantics:
#   optional = true       → enable = mkOption default false
#   optional = false/absent → enable = mkOption default true
#
# When a dir has sub-entries, each sub gets its own enable option whose
# defaultText is "config.<ns>.<parent>.enable" — so setting the parent
# to false cascades to all subs (and an explicit per-sub override still wins).
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
  # `imports = [ ... ]` list from entries.
  mkImports =
    basePath: entries:
    map (
      e:
      if e ? source && e.source != null then
        e.source
      else if e.kind == "dir" then
        basePath + "/${e.name}"
      else
        basePath + "/${e.name}.nix"
    ) entries;

  # An entry is enabled-by-default unless explicitly marked optional.
  isEnabledByDefault =
    e:
    !(e.optional or false);

  # One entry's contribution to options.<ns>.
  buildEntryOptions =
    ns: e:
    let
      parentPath = "${ns}.${e.name}";
      parentEnable = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = isEnabledByDefault e;
          defaultText = lib.literalExpression "config.${parentPath}.enable";
          description = "Enable ${e.name} module";
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
              ${sub.name}.enable = lib.mkOption {
                type = lib.types.bool;
                default = subDefault;
                defaultText = lib.literalExpression "config.${parentPath}.enable";
                description = "Enable ${e.name}.${sub.name} (tracks parent unless overridden)";
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
    { ${ns} = lib.foldl' (acc: e: acc // buildEntryOptions ns e) { } entries; };
in

{
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
