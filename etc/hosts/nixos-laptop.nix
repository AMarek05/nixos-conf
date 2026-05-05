# etc/hosts/nixos-laptop.nix — device config for the laptop
{ lib, ... }:

{
  imports = [
    ./laptop-hardware.nix
    ../mesa.nix
  ];

  networking.hostName = lib.mkForce "nixos-laptop";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;

  boot.kernelParams = [ "i915.enable_dpcd_backlight=3" ];

  services.upower.enable = true;
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 85"
  ];

  zramSwap.enable = true;
}
