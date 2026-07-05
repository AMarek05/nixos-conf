{ pkgs, lib, ... }:

{
  imports = [
    ./default.nix
    ./server
    ./hardware/server-hardware.nix
  ];

  networking = {
    hostName = "nixos-server";

    useDHCP = false;

    interfaces.ens18.ipv4.addresses = [
      {
        address = "10.20.30.10";
        prefixLength = 24;
      }
    ];

    defaultGateway = "10.20.30.1";
    nameservers = [
      "10.20.20.5"
      "8.8.8.8"
    ];
  };

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.qemuGuest.enable = true;

  nixosModules.desktop.audio.enable = false;
  nixosModules.desktop.console.enable = false;
  nixosModules.desktop.fonts.enable = false;
  nixosModules.gaming.gamemode.enable = false;
  nixosModules.desktop.hyprland.enable = false;
  nixosModules.security.sandbox.enable = false;
  nixosModules.system.nix-ld.enable = false;
  nixosModules.vpn.vpn.enable = false;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  system.stateVersion = lib.mkForce "25.11";
}
