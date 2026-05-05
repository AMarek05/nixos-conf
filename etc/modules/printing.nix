{ lib, ... }:
{
  options.modules.printing = {
    enable = lib.mkEnableOption "CUPS printing";
  };

  config = lib.mkIf config.modules.printing.enable {
    services.cups.enable = true;
  };
}
