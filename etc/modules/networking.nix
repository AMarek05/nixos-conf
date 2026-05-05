{ lib, config, ... }:
{
  options.modules.networking = {
    enable = lib.mkEnableOption "networking (NetworkManager, firewall, syncthing, openssh, extraHosts)";
  };

  config = lib.mkIf config.modules.networking.enable {
    networking.hostName = lib.mkDefault "nixos";

    networking.networkmanager.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;

    networking.firewall.allowedTCPPorts = [
      8000
      8384
    ];
    networking.firewall.checkReversePath = "loose";

    services.syncthing = {
      enable = true;
      user = "adam";
      openDefaultPorts = true;
      dataDir = "/home/adam";
      configDir = "/home/adam/.config/syncthing";
      guiAddress = "0.0.0.0:8384";
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    programs.mtr.enable = true;

    # resolve DNS conflicts
    # services.resolved.enable = true;

    networking.extraHosts = ''
      192.168.18.8 nixos-laptop
      192.168.18.13 nixos
    '';
  };
}
