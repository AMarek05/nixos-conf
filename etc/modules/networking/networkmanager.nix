# networking/networkmanager.nix — hostname and NetworkManager
{ lib, config }:
let
  cfg = config.modules.networking.networkmanager;
in
{
  config = lib.mkIf cfg.enable {
    networking.hostName = lib.mkDefault "nixos";

    networking.networkmanager.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
