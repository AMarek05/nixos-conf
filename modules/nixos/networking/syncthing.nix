{ lib, config, ... }:
{
  config =
    lib.mkIf (config.nixosModules.networking.enable && config.nixosModules.networking.syncthing.enable)
      {
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
