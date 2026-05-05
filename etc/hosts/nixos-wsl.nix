{ inputs, lib, ... }:
{
  imports = [
    ./common.nix
    ./configuration-wsl.nix
    inputs.nixos-wsl.nixosModules.default
  ];

  networking.hostName = lib.mkForce "nixos-wsl";
  system.stateVersion = "25.05";
  wsl.enable = true;
  wsl.defaultUser = "adam";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  modules = {
    audio.enable = lib.mkForce false;
    console.enable = lib.mkForce false;
    fonts.enable = lib.mkForce false;
    gamemode.enable = lib.mkForce false;
    networking.enable = lib.mkForce false;
    packages.enable = lib.mkForce false;
    printing.enable = lib.mkForce false;
    security.enable = lib.mkForce false;
    shell.enable = lib.mkForce false;
    user.enable = lib.mkForce false;
    nix-ld.enable = lib.mkForce false;
    flatpak.enable = lib.mkForce false;
    vpn.enable = lib.mkForce false;
  };
}
