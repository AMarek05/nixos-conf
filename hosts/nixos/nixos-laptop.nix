{ lib, ... }:
{
  imports = [
    ./default.nix
    ./hardware/laptop-hardware.nix
    ./hardware/gpu/mesa.nix
  ];

  nix = {
    distributedBuilds = true;
    settings = {
      cores = lib.mkForce 8;
    };

    buildMachines = [
      {
        hostName = "nixos";
        sshUser = "adam";
        sshKey = "/root/.ssh/id_root";
        system = "x86_64-linux";
        maxJobs = 8;
        speedFactor = 10;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];

    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

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
