{ config, pkgs, ... }:

{
  # Enable OpenGL/Vulkan
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (5th Gen) or newer (LIBVA_DRIVER_NAME=iHD)
      intel-vaapi-driver # For older processors (LIBVA_DRIVER_NAME=i965)
      libvdpau-va-gl
    ];
  };

  # Ensure the Plex user has access to the render node
  users.users.plex.extraGroups = [
    "render"
    "video"
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
