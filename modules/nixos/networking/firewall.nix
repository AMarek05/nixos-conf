{ lib, config, ... }:
{
  config =
    lib.mkIf (config.nixosModules.networking.enable && config.nixosModules.networking.firewall.enable)
      {
        networking.firewall.allowedTCPPorts = [
          8000
          8384
        ];
        networking.firewall.checkReversePath = "loose";
      };
}
