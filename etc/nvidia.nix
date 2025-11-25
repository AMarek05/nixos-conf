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
}
