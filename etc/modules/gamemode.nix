{ lib, ... }:
{
  options.modules.gamemode = {
    enable = lib.mkEnableOption "gamemode and steam";
  };

  config = lib.mkIf config.modules.gamemode.enable {
    programs.gamemode.enable = true;
    programs.steam.enable = true;
  };
}
