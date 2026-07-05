{ inputs, lib, ... }:
{
  imports = [
    ./default.nix
    ../configuration-wsl.nix
    inputs.nixos-wsl.nixosModules.default
  ];

  networking.hostName = lib.mkForce "nixos-wsl";

  wsl.enable = true;
  wsl.defaultUser = "adam";

  nixosModules.desktop.audio.enable = false;
  nixosModules.desktop.console.enable = false;
  nixosModules.desktop.fonts.enable = false;
  nixosModules.gaming.gamemode.enable = false;
  nixosModules.desktop.hyprland.enable = false;
  nixosModules.networking.enable = false;
  nixosModules.nix-ld.enable = false;
  nixosModules.security.enable = false;
  nixosModules.shell.enable = false;
  nixosModules.user.enable = false;
  nixosModules.network.vpn.enable = false;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.stateVersion = "25.05";
}
