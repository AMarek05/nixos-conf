# flake-parts Migration — TODO

## Goal
Replace the hand-written `outputs = inputs: { ... }` in `flake.nix` with the [flake-parts](https://github.com/hercules-ci/flake-parts) framework. Host configurations and module imports stay on disk exactly as they are; only `flake.nix` changes.

## Why flake-parts
- **Less wiring, more declarative** — `nixosConfigurations`, `homeConfigurations`, and `perSystem` are defined from lists and options, not copy-pasted blocks
- **`perSystem` auto-exposes `legacyPackages`** — `nix build .#nixosConfigurations.nixos.config.system.build` works without manual `package` declarations
- **Module-level defaults** — shared NixOS settings (`etc/hosts/default.nix`) and shared HM base (`hosts/common.nix`) can be declared once as flake-parts module defaults, not imported in every host file
- **`excludeModules` becomes a flake-parts option** — the per-name module exclusion in `lib/modules.nix` (which doesn't exist on this branch) can map to a first-class option
- **DevShell is mechanical** — adding a devShell for the flake itself is a few lines, not a custom `outputs` block

## Current Structure

```
flake.nix               16 inputs · hand-written outputs · no lib/modules.nix
                        hmPkgs built manually with customOverlays (grimblast)
                        commonImports (sops-nix, nix-index, nixpkgs.overlays)
                        manually wires 3 nixosConfigurations + 3 homeConfigurations

etc/
  hosts/
    default.nix         shared NixOS base (lix, nix.settings, boot.kernelPackages,
                        timezone, udisks, services.udev.packages, etc.)
    nixos.nix           NixOS host: imports ./default.nix + hardware + singletons
    nixos-laptop.nix    NixOS host
    nixos-wsl.nix       NixOS host
    hardware/           (empty?)
  modules/
    default.nix         NixOS module aggregator (audio, packages, nix-ld, sandbox,
                        gamemode, user, shell, console, fonts, security,
                        networking, vpn) + { user.enable, audio.enable, ... } options
    audio.nix, packages.nix, nix-ld.nix, sandbox.nix, gamemode.nix,
    user.nix, shell.nix, console.nix, fonts.nix, security.nix,
    networking.nix, vpn.nix
  hyprland.nix, mesa.nix, nvidia.nix, openclaw.nix, configuration-wsl.nix
  OpenClaw/

hosts/
  common.nix            HM base: imports ../modules/default.nix (HM aggregator)
                        sets home.user + lix + HM enable + allowUnfree
  nixos.nix              HM config: imports common.nix + modules/forge.nix
  nixos-laptop.nix       HM config: imports common.nix + modules/forge.nix
  nixos-wsl.nix           HM config: imports common.nix only

modules/                 HM modules
  default.nix            HM aggregator (git, util, env, links, terminal, shell,
                          hyprland, apps, caelestia) + { env.enable, ... } options
  git.nix, util.nix, env.nix, links.nix
  terminal/default.nix + ghostty.nix, man.nix, tmux.nix
  shell/default.nix + scripts.nix, starship.nix, zsh.nix
  hyprland/default.nix + animations.nix, binds.nix, display.nix, windowrules.nix
  apps/main.nix + dolphin.nix, nvf.nix, nvim, stylix.nix
  caelestia/default.nix + ...
  forge.nix
```

**Two independent module trees:**
- NixOS tree: `etc/modules/` → `etc/hosts/nixos*.nix`
- HM tree: `modules/` → `hosts/nixos*.nix`
- Bridge: `hosts/common.nix` (HM) imports `modules/default.nix` (HM aggregator)

---

## Phase 1 — Add flake-parts input

- [ ] Add `flake-parts` to `inputs` in `flake.nix`
- [ ] Run `nix flake update` to lock it
- [ ] Add `imports = [ inputs.flake-parts.flakeModules.easy-achievement ]` or similar to top-level

---

## Phase 2 — Restructure `outputs` with mkFlake

**Before:**
```nix
outputs = { nixpkgs, home-manager, ... }@inputs: let hmPkgs = import nixpkgs { ...; overlays = [ customOverlays ]; }; in {
  nixosConfigurations = {
    nixos = nixpkgs.lib.nixosSystem { specialArgs = { inherit inputs; }; modules = [ ./etc/hosts/nixos.nix ] ++ commonImports; };
    ...
  };
  homeConfigurations = {
    "adam@nixos" = home-manager.lib.homeManagerConfiguration { pkgs = hmPkgs; modules = [ ./hosts/nixos.nix ./modules/forge.nix ]; ... };
    ...
  };
};
```

**After (flake-parts):**
```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
    systems = [ "x86_64-linux" ];

    perSystem = { config, pkgs', self, ... }: {
      packages = inputs.flake-parts.lib.fillMissingOutputs { }

      devShells.default = pkgs'.mkShell {
        inputsFrom = [ config.packages.default ];
      };
    };

    # NixOS configurations — declarative from host list
    flakeModules.easy-achievement = {
      temperatureBase = 40;

      _module.args = {
        allHosts = [
          { name = "nixos";       isLaptop = false; isWsl = false; }
          { name = "nixos-laptop"; isLaptop = true;  isWsl = false; }
          { name = "nixos-wsl";   isLaptop = false; isWsl = true;  }
        ];
      };
    };
  });
```

---

## Phase 3 — NixOS Configs via flake-parts

- [ ] Define `allHosts` as a `flake-parts` module argument
- [ ] Generate `nixosConfigurations` from `allHosts` using `mapChannels` or direct attrset construction inside the flake-parts module
- [ ] Wire `commonImports` (sops-nix, nix-index, nixpkgs.overlays) as module defaults instead of repeating in each host
- [ ] Wire `etc/hosts/default.nix` as a module default (shared base for all NixOS hosts)
- [ ] Remove manual `commonImports` list from `flake.nix`

---

## Phase 4 — HM Configs via flake-parts

- [ ] Generate `homeConfigurations` from host list similarly
- [ ] Wire `hosts/common.nix` as HM module default
- [ ] Handle per-host `modules` additions (e.g. `modules/forge.nix` for nixos + nixos-laptop but not nixos-wsl)
- [ ] Keep `hmPkgs` override (`customOverlays` for grimblast) — passes through `perSystem`

---

## Phase 5 — Per-system overlay

- [ ] Move `customOverlays` (grimblast override) into `perSystem.packages` or a dedicated overlay output
- [ ] `perSystem` receives `pkgs'` with overlay already applied — no manual `import nixpkgs { overlays = [...] }` needed in `outputs`

---

## Phase 6 — Verify build

- [ ] `nix build .#nixosConfigurations.nixos.config.system.build` — boots clean
- [ ] `nix build .#nixosConfigurations.nixos-laptop...` — same
- [ ] `nix build .#nixosConfigurations.nixos-wsl...` — same
- [ ] `nix run .#homeConfigurations."adam@nixos"` — HM applies cleanly
- [ ] `nix develop` — devShell works
- [ ] `nix flake check` — no errors

---

## Out of Scope (don't touch)

- Module contents of `etc/modules/`, `modules/`, `etc/hosts/`, `hosts/` — they stay exactly as-is
- `etc/hosts/hardware/` — leave it empty or unexamined
- `modules/nvim/` directory listing failed but that's fine — doesn't affect the migration

---

## Key Design Decisions Needed

1. **`flakeModules.easy-achievement` vs raw flake-parts module** — `easy-achievement` is the simplest entry point but imposes some conventions. Raw flake-parts (`inputs.flake-parts.lib.mkFlake { ... }` with explicit `nixosConfigurations` block) gives more control. Recommendation: start with raw, move to `easy-achievement` if it fits.

2. **`allHosts` structure** — each host entry needs `{ name, isLaptop, isWsl }` to drive conditional module inclusion (laptop has battery, WSL has its own module set, etc.). Confirm this is the right shape.

3. **Singletons (nvidia, hyprland, openclaw, aagl)** — currently imported in `etc/hosts/nixos.nix`. Should these stay per-host in the host NixOS files, or should they become a `flake-parts` option like `enableHyprland = true` that auto-injects the module?

4. **`hosts/common.nix` as HM default** — it sets `home.username`, `home.homeDirectory`, `lix`, `home-manager.enable`, `allowUnfree`. With flake-parts this could be the HM module default instead of each host importing it. But `hosts/nixos.nix` and `hosts/nixos-laptop.nix` pass different extra modules. Handle by having the per-host modules override/extend, not replace.