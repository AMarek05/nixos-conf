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

  nixosModules.desktop.enable = false;
  nixosModules.gaming.enable = false;
  nixosModules.security.enable = false;
  nixosModules.system.user.enable = false;
  nixosModules.vpn.enable = false;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.stateVersion = "25.05";
}
