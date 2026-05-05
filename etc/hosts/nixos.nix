# etc/hosts/nixos.nix — device config for the desktop nixos machine
{ lib, ... }:

{
  imports = [
    ./nixos-hardware.nix
    ../openclaw.nix
    ../nvidia.nix
  ];

  networking.hostName = lib.mkForce "nixos";
}
