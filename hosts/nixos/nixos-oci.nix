# nixos-oci — OCI Ampere A1 (aarch64) VPS, hosts the Pangolin reverse-proxy. nixos-anywhere install.
{
  lib,
  ...
}:
{
  imports = [
    ./default.nix
    ./oci
  ];

  networking.hostName = lib.mkForce "nixos-oci";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    # 26.05 wants mirroredBoots non-empty even with efiInstallAsRemovable; path is a marker, not a mountpoint.
    mirroredBoots = [
      {
        path = "/boot";
        devices = [ "nodev" ];
      }
    ];
  };
  boot.loader.efi.canTouchEfiVariables = false;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty1"
  ];

  nixosModules.desktop.enable = false;
  nixosModules.gaming.enable = false;
  nixosModules.security.enable = false;
  nixosModules.vpn.enable = false;

  nixosModules.networking.syncthing.enable = false;
  nixosModules.shell.zsh.enable = false;
  nixosModules.shell.direnv.enable = false;
  nixosModules.shell.dconf.enable = false;
  nixosModules.system.packages.enable = false;

  system.stateVersion = lib.mkForce "25.05";
}
