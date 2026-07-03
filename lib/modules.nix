# lib/modules.nix
# Shared module library for modules/nixos/ and modules/hm/.
#
# Each entry drives:
#   1. The imports list (path to ./name.nix or ./name/)
#   2. Default enable values for <namespace>.<name>[/<sub>].enable
#
# optional = true  → enable = lib.mkDefault false  (off by default)
# optional = false / absent → enable = lib.mkDefault true (on by default)
#
# When a dir entry has sub-entries, BOTH the parent and each sub get
# their own independent enable default.
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
  # Build the `imports = [ ... ]` list from entries.
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

  # An entry is enabled-by-default (true) unless explicitly marked optional.
  # Resolves the optional field with a safe lookup.
  isEnabledByDefault =
    e:
    !(e.optional or false);

  # Build a single entry's contribution to the config attrset.
  # Returns { <name>.enable = ...; ...?sub-enables }
  buildEntry =
    e:
    if e.kind == "dir" && e ? sub then
      let
        subAcc = lib.foldl' (
          a: sub: a // { ${sub.name}.enable = lib.mkDefault (isEnabledByDefault sub); }
        ) { } e.sub;
      in
      {
        ${e.name} = {
          enable = lib.mkDefault (isEnabledByDefault e);
        } // subAcc;
      }
    else
      { ${e.name}.enable = lib.mkDefault (isEnabledByDefault e); };

  # Build { <namespace> = { ... enables ... }; }
  mkConfig =
    namespace: entries:
    { ${namespace} = lib.foldl' (acc: e: acc // buildEntry e) { } entries; };
in

{
  mkHostModules =
    { namespace, basePath, entries }:
    {
      imports = mkImports basePath entries;
      config = mkConfig namespace entries;
    };
}
