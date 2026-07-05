{ lib, config, ... }:
{
  config = lib.mkIf (config.nixosModules.networking.enable && config.nixosModules.networking.tools.enable) {
    programs.mtr.enable = true;
  };
}
