{ lib, config, ... }:
{
  # Cross-cutting networking config: hostname and extraHosts.
  # Sub-modules (nm, firewall, syncthing, ssh, tools) are auto-imported.
  config = lib.mkIf config.nixosModules.networking.enable {

    services.resolved.enable = true;

    networking = {
      hostName = lib.mkDefault "nixos";

      networkmanager.enable = true;

      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      extraHosts = ''
        20.100.176.55 azure
        192.168.18.8 nixos-laptop
        192.168.18.13 nixos
      '';
    };

    systemd.services.NetworkManager-wait-online.enable = false;
    programs.mtr.enable = true;

  };
}
