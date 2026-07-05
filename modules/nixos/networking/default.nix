{ lib, config, ... }:
{
  # Cross-cutting networking config: hostname and extraHosts.
  # Sub-modules (nm, firewall, syncthing, ssh, tools) are auto-imported.
  config = lib.mkIf config.nixosModules.networking.enable {
    networking.hostName = lib.mkDefault "nixos";

    networking.extraHosts = ''
      20.100.176.55 azure
      192.168.18.8 nixos-laptop
      192.168.18.13 nixos
    '';
  };
}
