{ pkgs, lib, ... }:

{
  imports = [
    ./default.nix
    ./server
    ./hardware/server-hardware.nix
  ];

  nix.settings = {
    max-jobs = lib.mkForce 2;
    cores = lib.mkForce 4;
  };

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

  nixosModules.desktop.enable = false;
  nixosModules.gaming.enable = false;
  nixosModules.security.enable = false;
  nixosModules.vpn.enable = false;

  nixosModules.networking.syncthing.enable = false;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200"
  ];

  system.stateVersion = lib.mkForce "25.11";
}
