{ lib, config, ... }:
{
  config = lib.mkIf (config.nixosModules.networking.enable && config.nixosModules.networking.nm.enable) {
    networking.networkmanager.enable = true;
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
