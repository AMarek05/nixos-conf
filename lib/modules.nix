# lib/modules.nix
# Shared module library — used by both the NixOS (etc/modules/) and
# Home Manager (modules/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (./name.nix or ./name/)
#   2. The modules.<name>.enable option default (true, or false for optional)
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
          children = if e.sub != null then mkModulesTree e.sub else {};
          base = if e.optional then { ${e.name} = { enable = lib.mkDefault false; }; }
                 else { ${e.name} = { enable = lib.mkDefault true; }; };
        in {
          name = e.name;
          value = base.${e.name} // children;
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