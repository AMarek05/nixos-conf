# lib/modules.nix
# Shared module library — used by both the NixOS (modules/nixos/) and
# Home Manager (modules/hm/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (path or ./name.nix / ./name/)
#   2. Default enable values for nixosModules.<name> / hmModules.<name>
#
# optional = true  → enable = lib.mkDefault false  (off by default)
# optional = false / absent → enable = lib.mkDefault true (on by default)
#
# When a dir entry has sub-entries:
#   - Parent dir gets hmModules.<name>.enable = lib.mkDefault true (unless optional)
#   - Each sub gets hmModules.<name>.<sub>.enable with its own default
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
  # Generate import paths from entries
  mkImports = basePath: entries:
    map (e:
      if e ? source && e.source != null then e.source
      else if e.kind == "dir" then basePath + "/${e.name}"
      else basePath + "/${e.name}.nix"
    ) entries;

  # Convert entries to nixosModules attribute set with defaults
  mkNixosModulesConfig = entries:
    lib.foldl' (acc: e:
      let
        defaultEnabled = !(e.optional or false);
      in
      acc // { ${e.name} = { enable = lib.mkDefault defaultEnabled; }; }
    ) { } entries;

  # Convert entries + sub-entries to hmModules attribute set with defaults
  # When a dir has sub-entries: sets BOTH parent enable AND sub enables
  mkHmModulesConfig = entries:
    lib.foldl' (acc: e:
      let
        # Dir with sub: set parent AND all sub entries
        mkDirWithSubConfig = name: subs:
          let
            parentDefault = !(e.optional or false);
            parentAcc = acc // { ${name} = { enable = lib.mkDefault parentDefault; }; };
          in
          lib.foldl' (a: sub:
            let
              subDefault = !(sub.optional or false);
              subName = "${name}.${sub.name}";
            in
            a // { ${subName} = { enable = lib.mkDefault subDefault; }; }
          ) parentAcc subs;
        # Dir with no sub: just set parent enable
        mkDirConfig = name:
          let defaultEnabled = !(e.optional or false); in
          acc // { ${name} = { enable = lib.mkDefault defaultEnabled; }; };
        # File entry: just set enable
        mkFileConfig = name:
          let defaultEnabled = !(e.optional or false); in
          acc // { ${name} = { enable = lib.mkDefault defaultEnabled; }; };
      in
      if e.kind == "dir" && e ? sub then mkDirWithSubConfig e.name e.sub
      else if e.kind == "dir" then mkDirConfig e.name
      else mkFileConfig e.name
    ) { } entries;
in

{
  # For NixOS module trees (modules/nixos/default.nix)
  mkHostNixosModules = { basePath, entries }: {
    imports = mkImports basePath entries;
    config = {
      nixosModules = mkNixosModulesConfig entries;
    };
  };

  # For Home Manager module trees (modules/hm/default.nix)
  mkHostHmModules = { basePath, entries }: {
    imports = mkImports basePath entries;
    config = {
      hmModules = mkHmModulesConfig entries;
    };
  };
}