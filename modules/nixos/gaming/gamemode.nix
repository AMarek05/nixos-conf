{ lib, config, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "gaming.gamemode") {
    programs.gamemode.enable = true;
    programs.steam.enable = true;
  };
}
