# lib/modules.nix
# Shared module library — used by both the NixOS (etc/modules/) and
# Home Manager (modules/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (path or ./name.nix / ./name/)
#   2. The modules.<opt>.enable option default (true, or false for optional)
#
# Usage in a default.nix:
#
#   let modulesLib = import ../../lib/modules.nix { inherit lib; };
#   in modulesLib.mkHostNixosModules {
#     basePath = ../../etc/modules;
#     entries = [ ... ];
#   }
#
{ lib }:

let
  # Recursively build the modules attribute set from a list of entries.
  # Each entry may have `sub` children for nested enable flags.
  mkModulesTree = entries:
    builtins.listToAttrs (
      map (e:
        let
          optName = if e ? opt then e.opt else e.name;
          children = if e ? sub && e.sub != null then mkModulesTree e.sub else {};
          base =
            if e ? optional && e.optional
            then { ${optName} = { enable = lib.mkDefault false; }; }
            else { ${optName} = { enable = lib.mkDefault true; }; };
        in {
          name = optName;
          value = base.${optName} // children;
        }
      ) entries
    );

  mkImports = basePath: entries:
    map (e:
      if e ? source && e.source != null then e.source
      else if e.kind == "dir" then basePath + "/${e.name}"
      else basePath + "/${e.name}.nix"
    ) entries;
in

{
  # For NixOS module trees (etc/modules/default.nix replacement)
  mkHostNixosModules = { basePath, entries }: {
    imports = mkImports basePath entries;
    modules = mkModulesTree entries;
  };

  # For Home Manager module trees (modules/default.nix replacement)
  mkHostHmModules = { basePath, entries }: {
    imports = mkImports basePath entries;
    modules = mkModulesTree entries;
  };
}