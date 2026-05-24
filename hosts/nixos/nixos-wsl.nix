{ inputs, lib, ... }:
{
  imports = [
    ./default.nix
    ../configuration-wsl.nix
    inputs.nixos-wsl.nixosModules.default
  ];

  networking.hostName = lib.mkForce "nixos-wsl";
  system.stateVersion = "25.05";
  wsl.enable = true;
  wsl.defaultUser = "adam";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
}
