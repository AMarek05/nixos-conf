# TODO: Shared Module Library for `etc/modules/` and `modules/`

## Problem: Duplicated Aggregator Pattern

Both module trees contain a structurally identical pattern:

```
etc/modules/default.nix     ← NixOS modules (imported by etc/hosts/default.nix)
modules/default.nix         ← Home Manager modules (imported by hosts/common.nix)
```

Each `default.nix` does two things:
1. Imports sub-modules as plain Nix imports
2. Defines a `modules = { ... }` option set that exposes enable/disable toggles for each sub-module

The `modules` option set in both files follows the exact same shape:

```nix
modules = {
  audio.enable    = lib.mkDefault true;   # etc/modules/default.nix
  networking.enable = lib.mkDefault true;  # etc/modules/default.nix

  git.enable = lib.mkDefault true;         # modules/default.nix
  env.enable = lib.mkDefault true;         # modules/default.nix
};
```

And the sub-modules themselves (e.g., `audio.nix`, `git.nix`) are self-contained and completely independent of which aggregator they belong to. They just receive `lib` and `config` and define their own `options.modules.<name>` and `config.modules.<name>` blocks.

The result is two near-identical aggregator files that must be kept in sync manually. Adding a new module requires editing two `default.nix` files in parallel.

---

## Proposed Fix: Shared Module Library at `lib/modules.nix`

Create a new file at the repo root: `lib/modules.nix`.

This file exports two helper functions (pure Nix — no IFD):

```
mkHostNixosModules  → produces the etc/modules/default.nix content
mkHostHmModules    → produces the modules/default.nix content
```

Both functions accept an attribute set describing the module entries:

```nix
{
  # Each entry:
  #   name      = filename (without .nix) / directory name
  #   kind      = "file" | "dir"
  #   optional  = true  → sandbox.enable = lib.mkDefault false
  #              false → sandbox.enable = lib.mkDefault true
  #   subModules = [ ... ]  (only for kind = "dir", list of relative imports)
  entries = [
    { name = "audio";      kind = "file";   optional = false; }
    { name = "packages";   kind = "file";   optional = false; }
    { name = "sandbox";    kind = "file";   optional = true;  }
    { name = "terminal";   kind = "dir";    optional = false; subModules = [ ./default.nix ]; }
    { name = "shell";       kind = "dir";    optional = false; subModules = [ ./default.nix ./starship.nix ]; }
  ];
}
```

The helper generates:
- `imports = [ ./audio.nix ./packages.nix ... ]` (all entries)
- `modules = { audio.enable = lib.mkDefault true; sandbox.enable = lib.mkDefault false; ... }`

---

## Files to Change

### New file: `lib/modules.nix`

```nix
# lib/modules.nix
# Shared module library — used by both the NixOS (etc/modules/) and
# Home Manager (modules/) module trees to avoid duplicated aggregator
# default.nix files.
#
# Each entry drives:
#   1. The imports list (./name.nix or ./name/)
#   2. The modules.<name>.enable option default (true, or false for optional)
#
# Usage:
#
#   let modulesLib = import ./lib/modules.nix;
#   in modulesLib.mkHostNixosModules { entries = [ ... ]; }
#
{ lib }:

let
  mkModules = entries:
    builtins.listToAttrs (
      map (e: {
        name = e.name;
        value =
          if e.optional
          then lib.mkDefault false
          else lib.mkDefault true;
      }) entries
    );

  mkImports = entries:
    map (e:
      if e.kind == "dir" then ./${e.name}
      else ./${e.name}.nix
    ) entries;
in

{
  # For NixOS module trees (etc/modules/default.nix replacement)
  mkHostNixosModules = { entries }: {
    imports = mkImports entries;
    modules = mkModules entries;
  };

  # For Home Manager module trees (modules/default.nix replacement)
  mkHostHmModules = { entries }: {
    imports = mkImports entries;
    modules = mkModules entries;
  };
}
```

### Change: `etc/modules/default.nix`

Replace the hand-maintained file with:

```nix
{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix;
in
modulesLib.mkHostNixosModules {
  entries = [
    # files
    { name = "audio";      kind = "file"; optional = false; }
    { name = "packages";   kind = "file"; optional = false; }
    { name = "nix-ld";     kind = "file"; optional = false; }
    { name = "sandbox";    kind = "file"; optional = true;  }
    { name = "gamemode";   kind = "file"; optional = false; }
    { name = "user";       kind = "file"; optional = false; }
    { name = "shell";      kind = "file"; optional = false; }
    { name = "console";    kind = "file"; optional = false; }
    { name = "fonts";      kind = "file"; optional = false; }
    { name = "security";   kind = "file"; optional = false; }
    { name = "networking"; kind = "file"; optional = false; }
    { name = "vpn";        kind = "file"; optional = false; }
  ];
}
```

### Change: `modules/default.nix`

Replace the hand-maintained file with:

```nix
{ lib, ... }:

let
  modulesLib = import ../lib/modules.nix;
in
modulesLib.mkHostHmModules {
  entries = [
    # files
    { name = "git";   kind = "file"; optional = false; }
    { name = "util";  kind = "file"; optional = false; }
    { name = "env";   kind = "file"; optional = false; }
    { name = "links"; kind = "file"; optional = false; }
    # dirs
    { name = "terminal"; kind = "dir"; optional = false; }
    { name = "shell";    kind = "dir"; optional = false; }
    { name = "hyprland"; kind = "dir"; optional = false; }
    # apps dir (flat files within dir, main.nix handles the imports)
    { name = "apps";   kind = "dir";  optional = false; }
    { name = "caelestia"; kind = "dir"; optional = false; }
  ];
}
```

> Note: The `modules/apps/` entry is a special case — `apps/main.nix` imports `apps/dolphin.nix`, `apps/nvf.nix`, `apps/stylix.nix`, and `apps/nvim/` as sub-modules (not `apps/default.nix`). The `apps/` dir has no `default.nix`. To support this, `mkImports` needs to handle a `source` attribute for custom import paths:
>
> ```
> { name = "apps"; kind = "dir"; optional = false; source = ./apps/main.nix; }
> ```
>
> If no `source` is given, it falls back to `./${name}` (the directory).

### Change: `lib/modules.nix` (update with source support)

```nix
{ lib }:

let
  mkModules = entries:
    builtins.listToAttrs (
      map (e: {
        name = e.name;
        value =
          if e.optional
          then lib.mkDefault false
          else lib.mkDefault true;
      }) entries
    );

  mkImports = entries:
    map (e:
      if e.source != null then e.source
      else if e.kind == "dir" then ./${e.name}
      else ./${e.name}.nix
    ) entries;
in

{
  mkHostNixosModules = { entries }: {
    imports = mkImports entries;
    modules = mkModules entries;
  };

  mkHostHmModules = { entries }: {
    imports = mkImports entries;
    modules = mkModules entries;
  };
}
```

---

## What Does NOT Change

- `etc/hosts/default.nix` — still imports `../modules` (unchanged import path)
- `hosts/common.nix` — still imports `../modules/default.nix` (unchanged import path)
- All individual module files under `etc/modules/*.nix` — untouched
- All individual module files under `modules/*.nix`, `modules/*/` — untouched
- `hosts/hardware/` and `etc/hosts/hardware/` — kept separate as instructed

---

## Order of Implementation

1. Create `lib/modules.nix` (new file)
2. Update `etc/modules/default.nix` to use `mkHostNixosModules`
3. Update `modules/default.nix` to use `mkHostHmModules`
4. Commit and test: `nixos-rebuild switch --flake .#nixos` and `home-manager switch --flake .#adam@nixos`

---

## Benefits

- Single source of truth for the module list
- Adding a module: edit `lib/modules.nix` entries in one place, both trees updated
- Both aggregators remain structurally identical via the shared helper
- Hardware modules (`etc/hosts/hardware/`, `hosts/`) are unaffected
- No IFD (imports are deferred, no eval cost at flake parse time)