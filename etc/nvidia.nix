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
    (
      (koboldcpp.override {
        config.cudaSupport = true;
        cublasSupport = true;
        cudaPackages = cudaPackages_13;
      }).overrideAttrs
      (oldAttrs: {
        postPatch = ''
          # 1. Keep the original author's patch to survive the Nix build sandbox
          nixLog "patching $PWD/Makefile to remove explicit linking against CUDA driver"
          substituteInPlace "$PWD/Makefile" \
            --replace-fail \
              'CUBLASLD_FLAGS = -lcuda ' \
              'CUBLASLD_FLAGS = '

          # 2. Our patch to compile for the RTX 5080 (Blackwell)
          nixLog "patching Makefile to force Blackwell architecture instead of native"
          substituteInPlace "$PWD/Makefile" \
            --replace-warn "-arch=native" "-arch=sm_120"
        '';

        # 3. Force load the NVIDIA driver at runtime so Python can find cuMemCreate
        postFixup = (oldAttrs.postFixup or "") + ''
          wrapProgram "$out/bin/koboldcpp" \
            --prefix LD_PRELOAD : "/run/opengl-driver/lib/libcuda.so.1"
        '';
      })
    )
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
