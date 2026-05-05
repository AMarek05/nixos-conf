# boot/kernel.nix — kernel package selection
{ pkgs }:
{
  boot.kernelPackages = pkgs.linuxPackages_zen;
}
