{ lib, config, ... }:
{
  options.modules.flatpak = {
    enable = lib.mkEnableOption "Sandboxing";
  };

  config = lib.mkIf config.modules.flatpak.enable {
    services.flatpak.enable = true;
  };
}
