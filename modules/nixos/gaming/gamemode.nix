{ lib, config, ... }:
{
  config =
    lib.mkIf (config.nixosModules.gaming.enable && config.nixosModules.gaming.gamemode.enable)
      {
        programs.gamemode.enable = true;
        programs.steam.enable = true;
      };
}
