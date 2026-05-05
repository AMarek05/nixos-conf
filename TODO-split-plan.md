# Plan: split etc/configuration.nix into etc/modules/

## Goal
Replace the ~400-line `etc/configuration.nix` monolith with a thin wire that imports
`etc/modules/default.nix`, which in turn imports domain-specific submodules.
Devices (nixos, nixos-laptop) disable what they don't need via module options.

## Architecture
```
etc/
├── configuration.nix           # thin wire: imports + stateVersion
├── modules/
│   └── default.nix            # enable flags + imports all domain folders
│
│   # Each domain folder has a default.nix that aggregates submodules.
│   # Submodules are split by function within the domain.
│
│   ├── boot/
│   │   ├── default.nix         # imports loader + kernel, declares enable flags
│   │   ├── loader.nix          # grub EFI/USB, theme, Windows entry, UEFI fw
│   │   └── kernel.nix         # kernelPackages = linuxPackages_zen
│   │
│   ├── networking/
│   │   ├── default.nix
│   │   ├── networkmanager.nix  # networkmanager + hostname
│   │   ├── firewall.nix       # firewall ports (8000, 8384), checkReversePath
│   │   └── services.nix       # mullvad-vpn (enable), tailscale (disable)
│   │
│   ├── user/
│   │   ├── default.nix
│   │   ├── accounts.nix        # adam user, groups, SSH key, shell = zsh
│   │   └── system-shells.nix  # programs.zsh.enable = true (system-wide)
│   │
│   ├── services/
│   │   ├── default.nix
│   │   ├── audio.nix          # pipewire + wireplumber rules, rtkit
│   │   ├── syncthing.nix
│   │   ├── flatpak.nix
│   │   ├── sshd.nix
│   │   └── gnome-keyring.nix
│   │
│   ├── i18n/
│   │   ├── default.nix
│   │   ├── locale.nix         # defaultLocale, extraLocaleSettings, timeZone
│   │   └── console.nix       # console font (ter-v16n), keyMap, terminus_font
│   │
│   ├── packages/
│   │   ├── default.nix
│   │   ├── system.nix         # vim, git, man-pages, rclone, gparted, alsa-*, etc.
│   │   └── gaming.nix         # steam-run-free, proton-vpn, mullvad-vpn wrappers, etc.
│   │
│   ├── nix/
│   │   ├── default.nix
│   │   ├── settings.nix       # substituters, trusted-public-keys, max-jobs, cores
│   │   └── ld.nix             # programs.nix-ld + library list
│   │
│   └── security/
│       ├── default.nix
│       ├── pam.nix            # hyprlock pam, login enableGnomeKeyring
│       └── gnupg.nix         # programs.gnupg.agent

## Stays flat (unchanged unless noted):
# etc/hyprland.nix        — greetd + hyprland (compositor, not splittable)
# etc/openclaw.nix         — OpenClaw gateway
# etc/nvidia.nix           — NVIDIA GPU config
# etc/mesa.nix             — AMD GPU config
# etc/configuration-wsl.nix — WSL-specific (different pattern, keep as-is)
# etc/hosts/nixos-hardware.nix — hardware scan (auto-generated, device-specific)
# etc/hosts/laptop-hardware.nix — hardware scan (auto-generated, device-specific)

## Module enable flags (in etc/modules/default.nix):
  modules.boot.enable = lib.mkDefault true;
  modules.networking.enable = lib.mkDefault true;
  modules.user.enable = lib.mkDefault true;
  modules.services.enable = lib.mkDefault true;
  modules.i18n.enable = lib.mkDefault true;
  modules.packages.enable = lib.mkDefault true;
  modules.nix.enable = lib.mkDefault true;
  modules.security.enable = lib.mkDefault true;

## Device override pattern (in flake.nix):
  modules.boot.grub.enable = lib.mkForce false;        # nixos-laptop uses systemd-boot
  modules.boot.grub.theme = lib.mkForce null;          # no theme on laptop
  modules.services.mullvad-vpn.enable = lib.mkForce false;  # laptop has no mullvad

## Implementation order:
1. Create etc/modules/ directory structure
2. Create all module files (boot, networking, user, services, i18n, packages, nix, security)
3. Replace etc/configuration.nix with thin wire
4. Update flake.nix sharedModules to point to new etc/configuration.nix (unchanged path)
5. Commit

## Notes:
- programs.zsh.enable = true stays in user/accounts.nix (belongs with user creation)
- environment.pathsToLink = [ "/share/zsh/" ] stays in user/system-shells.nix
- services.kmscon, services.flatpak, programs.direnv, programs.dconf — where?
  → services/ and programs/ that aren't boot/user/nix/security go in services/
- gamemode: gaming.nix (games), audio.nix (rtkit + pipewire concerns)
- Mullvad: networking/services.nix (VPN is a networking service), gaming.nix (proton-vpn-cli package)
