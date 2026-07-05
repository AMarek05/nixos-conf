{ lib, config, ... }:
{
  config = lib.mkIf config.nixosModules.gamemode.enable {
    programs.gamemode.enable = true;
    programs.steam.enable = true;
  };
}
