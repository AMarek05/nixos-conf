{
  lib,
  config,
  osConfig,
  osConfigs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mapAttrs;

  serverConfig = osConfigs."nixos-server".config;
  isServer = osConfig.networking.hostName == "nixos-server";

  cfg = config.hmModules.user.ssh;
in
{
  config = mkIf (cfg.enable) {
    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;

      settings = mkMerge [
        {
          "admin" = {
            HostName = "admin";
            User = "root";

            ForwardAgent = true;
          };

          "proxmox" = {
            HostName = "proxmox";
            User = "root";

            ProxyJump = "admin";
          };

          "nixos-server" = {
            HostName = "nixos-server";
            User = "adam";

            ProxyJump = "admin";
            ForwardAgent = true;
          };

          "hermes".ForwardAgent = true;

          "pangolin" = {
            HostName = "amarek.pl";
            Port = 2222;

            User = "ubuntu";
          };

          "polluks" = {
            HostName = "polluks.cs.put.poznan.pl";
            User = "inf164182";
          };
        }

        (mapAttrs (containerName: containerData: {
          HostName = containerData.localAddress;
          User = containerName;

          ProxyJump = lib.mkIf (!isServer) "nixos-server";
        }) serverConfig.containers)
      ];
    };
  };
}
