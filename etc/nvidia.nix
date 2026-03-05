{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  boot.tmp.useTmpfs = lib.mkForce false;

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    (koboldcpp.override {
      config.cudaSupport = true;
      cublasSupport = true;
      cudaArches = [ "sm_120" ];
    })
  ];

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = true;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
    libva-utils
    libva-vdpau-driver
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 12 * 1024;
    }
  ];
}
