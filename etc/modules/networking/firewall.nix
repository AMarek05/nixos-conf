# networking/firewall.nix — firewall ports and reverse-path checking
{ config, lib }:
let
  cfg = config.modules.networking.firewall;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      8000
      8384
    ];

    networking.firewall.checkReversePath = "loose";
  };
}
