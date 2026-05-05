{ lib, config, ... }:
{
  options.modules.sandbox = {
    enable = lib.mkEnableOption "Sandboxing";
  };

  config = lib.mkIf config.modules.sandbox.enable {
    services.flatpak.enable = true;
  };
}
