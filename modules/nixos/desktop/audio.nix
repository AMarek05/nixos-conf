{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "desktop.audio") {
    security.rtkit.enable = true;

    environment.systemPackages = [
      pkgs.pavucontrol
    ];

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };
  };
}
