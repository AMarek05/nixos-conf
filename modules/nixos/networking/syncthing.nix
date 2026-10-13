{ lib, config, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "networking.syncthing") {
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
