{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver

    vdpauinfo
    libva-utils

    libva-vdpau-driver
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";

    # Explicitly tell VDPAU to use the NVIDIA backend
    VDPAU_DRIVER = "nvidia";

    # Required for firefox/thunderbird if using the nvidia-vaapi-driver
    MOZ_DISABLE_RDD_SANDBOX = "1";

    # Use the direct backend for the VA-API driver
    NVD_BACKEND = "direct";
  };
}
