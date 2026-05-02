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

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Forces Mozilla to use the Wayland EGL backend properly
    MOZ_ENABLE_WAYLAND = "1";
  };

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
