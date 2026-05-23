# lib/modules.nix
# Shared module library — used by both the NixOS (modules/nixos/) and
# Home Manager (modules/hm/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (path or ./name.nix / ./name/)
#
# The attrset returned by mkHostNixosModules / mkHostHmModules only
# provides imports; no option declarations are generated. This avoids
# creating phantom option paths that don't correspond to real module
# options (e.g., modules.openclaw when the real path is services.openclaw).
#
# Usage in a default.nix:
#
#   let modulesLib = import ../../lib/modules.nix { inherit lib; };
#   in modulesLib.mkHostNixosModules {
#     basePath = ../../modules/nixos;
#     entries = [ ... ];
#   }
#
{ lib }:

let
  mkImports = basePath: entries:
    map (e:
      if e ? source && e.source != null then e.source
      else if e.kind == "dir" then basePath + "/${e.name}"
      else basePath + "/${e.name}.nix"
    ) entries;
in

{
  # For NixOS module trees (modules/nixos/default.nix)
  mkHostNixosModules = { basePath, entries }: {
    imports = mkImports basePath entries;
  };

  # For Home Manager module trees (modules/hm/default.nix)
  mkHostHmModules = { basePath, entries }: {
    imports = mkImports basePath entries;
  };
}