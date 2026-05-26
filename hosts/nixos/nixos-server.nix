{ pkgs, lib, ... }:
{
  imports = [
    ./hardware/server-hardware.nix
  ];

  networking.hostName = "nixos-server";

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  nixosModules.audio.enable = false;
  nixosModules.console.enable = false;
  nixosModules.fonts.enable = false;
  nixosModules.gamemode.enable = false;
  nixosModules.hyprland.enable = false;
  nixosModules.networking.enable = false;
  nixosModules.nix-ld.enable = false;
  nixosModules.packages.enable = false;
  nixosModules.security.enable = false;
  nixosModules.shell.enable = false;
  nixosModules.vpn.enable = false;

  system.stateVersion = "25.11";
}
