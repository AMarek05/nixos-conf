# etc/hosts/nixos-wsl.nix — device overrides for WSL
# WSL keeps its own configuration-wsl.nix as base; this file applies only
# the hostname override. Do not add imports here — would duplicate user/networking.
{ lib }:

{
  networking.hostName = lib.mkForce "nixos-wsl";
}
