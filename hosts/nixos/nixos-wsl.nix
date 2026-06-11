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

  nixosModules.audio.enable = false;
  nixosModules.console.enable = false;
  nixosModules.fonts.enable = false;
  nixosModules.gamemode.enable = false;
  nixosModules.hyprland.enable = false;
  nixosModules.networking.enable = false;
  nixosModules.nix-ld.enable = false;
  nixosModules.security.enable = false;
  nixosModules.shell.enable = false;
  nixosModules.vpn.enable = false;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.stateVersion = "25.05";
}
