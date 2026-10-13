{ lib, config, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "networking.firewall") {
    networking.firewall.allowedTCPPorts = [
      8000
      8384
    ];
    networking.firewall.checkReversePath = "loose";
  };
}
