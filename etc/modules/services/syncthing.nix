# services/syncthing.nix
{ lib, config }:
let
  cfg = config.modules.services.syncthing;
in
{
  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      user = "adam";
      openDefaultPorts = true;

      dataDir = "/home/adam";
      configDir = "/home/adam/.config/syncthing";

      guiAddress = "0.0.0.0:8384";
    };
  };
}
