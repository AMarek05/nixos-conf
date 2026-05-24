# lib/modules.nix
# Shared module library — used by both the NixOS (modules/nixos/) and
# Home Manager (modules/hm/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The import paths (path or ./name.nix / ./name/)
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
#   let modulesLib = import ../../lib/modules.nix { inherit lib pkgs; };
#   in modulesLib.mkHostNixosModules {
#     basePath = ../../modules/nixos;
#     entries = [ ... ];
#   }
#
{ lib, pkgs }:

let
  # Generate import paths from entries
  mkImportLines = basePath: entries:
    let
      mkEntry = e:
        if e ? source && e.source != null then
          "  (import ${lib.strings.escapeNixString e.source})"
        else if e.kind == "dir" then
          "  (lib.mkIf config.nixosModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}")}) ])"
        else
          "  (lib.mkIf config.nixosModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}.nix")}) ])";
    in
    lib.concatMapStringsSep "\n" mkEntry entries;

  # Generate proxy module string
  mkNixosProxy = basePath: entries: ''
    {
      imports = lib.flatten [
        ${
          # For each entry, conditionally import the module
          lib.concatMapStringsSep "\n" (e:
            if e ? source && e.source != null then
              "        (import ${lib.strings.escapeNixString e.source})"
            else if e.kind == "dir" then
              "        (lib.mkIf config.nixosModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}")}) ])"
            else
              "        (lib.mkIf config.nixosModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}.nix")}) ])"
          ) entries
        }
      ];
    }
  '';

  # Generate imports for HM — similar but with hmModules.<name>.<sub>.enable
  mkHmProxy = basePath: entries:
    let
      mkHmEntry = e:
        if e ? source && e.source != null then
          "        (import ${lib.strings.escapeNixString e.source})"
        else if e.kind == "dir" && e ? sub then
          # Dir with sub-entries: each sub gets its own mkIf
          lib.concatMapStringsSep "\n" (sub:
            "        (lib.mkIf config.hmModules.${e.name}.${sub.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}/${sub.name}.nix")}) ])"
          ) e.sub
        else if e.kind == "dir" then
          "        (lib.mkIf config.hmModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}")}) ])"
        else
          "        (lib.mkIf config.hmModules.${e.name}.enable [ (import ${lib.strings.escapeNixString (basePath + "/${e.name}.nix")}) ])";
    in
    "{
      imports = lib.flatten [
        ${
          lib.concatMapStringsSep "\n" (e: mkHmEntry e) entries
        }
      ];
    }";

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
        mkDirConfig = name:
          let defaultEnabled = !(e.optional or false); in
          acc // { ${name} = { enable = lib.mkDefault defaultEnabled; }; };
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
  mkHostNixosModules = { basePath, entries }:
    let
      proxy = pkgs.writeText "nixos-modules-proxy.nix" (mkNixosProxy basePath entries);
    in
    {
      imports = [
        proxy
      ];
      config = {
        nixosModules = mkNixosModulesConfig entries;
      };
    };

  # For Home Manager module trees (modules/hm/default.nix)
  mkHostHmModules = { basePath, entries }:
    let
      proxy = pkgs.writeText "hm-modules-proxy.nix" (mkHmProxy basePath entries);
    in
    {
      imports = [
        proxy
      ];
      config = {
        hmModules = mkHmModulesConfig entries;
      };
    };
}