# TODO: Full flake restructure — merge modules, move OpenClaw in, flatten hardware

## Target Structure

```
nixos-conf/
├── flake.nix
├── lib/
│   └── modules.nix              ← shared module library (updated basePaths)
├── modules/
│   ├── nixos/                   ← NixOS module tree
│   │   ├── default.nix          ← uses mkHostNixosModules (aggregator)
│   │   ├── audio.nix
│   │   ├── networking.nix
│   │   ├── sandbox.nix
│   │   ├── shell.nix            ← option name: modules.sysShell (needs opt = "sysShell")
│   │   ├── openclaw/             ← everything from etc/OpenClaw/
│   │   │   ├── default.nix
│   │   │   ├── modules/
│   │   │   ├── tools/
│   │   │   └── providers/
│   │   └── ...
│   ├── hm/                      ← HM module tree
│   │   ├── default.nix          ← uses mkHostHmModules (aggregator)
│   │   ├── git.nix
│   │   ├── env.nix
│   │   ├── links.nix
│   │   ├── util.nix
│   │   ├── apps/
│   │   ├── caelestia/
│   │   ├── hyprland/
│   │   ├── nvim/
│   │   ├── shell/
│   │   └── terminal/
│   └── hardware/                ← merged from etc/hosts/hardware/ + hosts/hardware/
│       ├── nixos/
│       └── nixos-laptop/
├── hosts/
│   ├── default.nix              ← common HM base (was hosts/common.nix)
│   ├── nixos.nix                ← forces modules.openclaw.enable = true
│   ├── nixos-laptop.nix
│   └── nixos-wsl.nix
└── store/
```

## What Stays the Same
- `flake.nix` — no structural changes
- `secrets/` and `store/` — unchanged

## Path Changes

### lib/modules.nix basePaths
- `mkHostNixosModules`: `basePath = ../../modules/nixos`
- `mkHostHmModules`: `basePath = ../../modules/hm`

### hosts/default.nix (was common.nix)
- `imports = [ ../modules/default.nix ]` → `imports = [ ../modules/hm/default.nix ]`

### etc/hosts/default.nix (→ hosts/default.nix)
- `imports = [ ../modules ]` → `imports = [ ../../modules/nixos ]`

### OpenClaw sops.nix
- Current: `sopsFile = ../../../secrets/openclaw.yaml` (from etc/OpenClaw/modules/)
- After move to `modules/nixos/openclaw/modules/`: `sopsFile = ../../../../secrets/openclaw.yaml`

### modules/nixos/default.nix (new aggregator)
- Uses `mkHostNixosModules` with `basePath = ../../modules/nixos`
- Entries: all etc/modules files + openclaw dir
- `shell` entry needs `opt = "sysShell"` (its module file declares `modules.sysShell`)

### hosts/nixos.nix
- Forces `modules.openclaw.enable = lib.mkForce true` to enable OpenClaw

## Order of Implementation

1. Create `modules/nixos/` and `modules/hm/` directory structure
2. Move `etc/modules/` files → `modules/nixos/` (NixOS modules)
3. Move `modules/` files (HM only) → `modules/hm/`
4. Move `etc/OpenClaw/` → `modules/nixos/openclaw/`
5. Fix `sops.nix` sopsFile path (+2 levels of `../`)
6. Create `modules/hardware/` merging both hardware trees
7. Update `lib/modules.nix` basePaths
8. Create `modules/nixos/default.nix` using mkHostNixosModules (with shell opt)
9. Update `modules/hm/default.nix` basePath and HM entries (apps/shell/terminal/hyprland sub)
10. Rename `hosts/common.nix` → `hosts/default.nix`, update import path
11. Update `etc/hosts/default.nix` import path (→ ../../modules/nixos)
12. Add OpenClaw enable to `hosts/nixos.nix`
13. Delete `etc/` directory
14. Delete `hosts/hardware/` (merged into `modules/hardware/`)
15. Commit and test

## OpenClaw Integration
- OpenClaw is a NixOS module (systemd, apparmor, sops) — lives in `modules/nixos/openclaw/`
- In `modules/nixos/default.nix`: `{ name = "openclaw"; kind = "dir"; }` — enabled by default
- `hosts/nixos.nix`: forces on with `modules.openclaw.enable = lib.mkForce true`
- Not enabled on `nixos-laptop` or `nixos-wsl` unless explicitly added