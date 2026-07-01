{ lib, pkgs, ... }:
{
  imports = [
    ./default.nix
    ./hardware/laptop-hardware.nix
    ./hardware/gpu/mesa.nix
  ];

  nixosModules.tailscale.enable = lib.mkForce true;

  networking.hostName = lib.mkForce "nixos-laptop";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;

  boot.kernelParams = [ "i915.enable_dpcd_backlight=3" ];

  services.upower.enable = true;
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 85"
  ];

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.sunshine.enable = true;

  environment.systemPackages = with pkgs; [ moonlight-qt ];

  zramSwap.enable = true;
}
