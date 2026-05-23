{ lib, config, ... }:
{
  options.nixosModules.gamemode = {
    enable = lib.mkEnableOption "gamemode and steam";
  };

  config = lib.mkIf config.nixosModules.gamemode.enable {
    programs.gamemode.enable = true;
    programs.steam.enable = true;
  };
}
