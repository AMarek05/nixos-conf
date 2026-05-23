# lib/modules.nix
# Shared module library — used by both the NixOS (modules/nixos/) and
# Home Manager (modules/hm/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (path or ./name.nix / ./name/)
#   2. Default enable values for nixosModules.<name> / hmModules.<name>
#
# Sub-entries (for dir entries with nested sub-modules) are flattened
# into dot-path option names: e.g., shell.zsh → hmModules.shell.zsh.enable
#
# optional = true  → enable = lib.mkDefault false  (off by default)
# optional = false / absent → enable = lib.mkDefault true (on by default)
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
  mkHmModulesConfig = entries:
    lib.foldl' (acc: e:
      let
        mkSubConfig = parentName: subs:
          lib.foldl' (a: sub:
            let
              subDefault = !(sub.optional or false);
              subName = "${parentName}.${sub.name}";
            in
            a // { ${subName} = { enable = lib.mkDefault subDefault; }; }
          ) a subs;
        mkDirConfig = name:
          let defaultEnabled = !(e.optional or false); in
          acc // { ${name} = { enable = lib.mkDefault defaultEnabled; }; };
        mkFileConfig = name:
          let defaultEnabled = !(e.optional or false); in
          acc // { ${name} = { enable = lib.mkDefault defaultEnabled; }; };
      in
      if e.kind == "dir" && e ? sub then mkSubConfig e.name e.sub
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