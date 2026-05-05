{ lib, ... }:
{
  options.modules.flatpak = {
    enable = lib.mkEnableOption "Flatpak sandboxing";
  };

  config = lib.mkIf config.modules.flatpak.enable {
    services.flatpak.enable = true;
  };
}
