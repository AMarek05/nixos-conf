# networking/default.nix
{ lib }:
{
  imports = [
    ./networkmanager.nix
    ./firewall.nix
    ./services.nix
  ];

  options.modules.networking = {
    enable = lib.mkEnableOption "networking";
    networkmanager = {
      enable = lib.mkEnableOption "networking/networkmanager";
    };
    firewall = {
      enable = lib.mkEnableOption "networking/firewall";
    };
    services = {
      enable = lib.mkEnableOption "networking/services";
    };
  };
}
