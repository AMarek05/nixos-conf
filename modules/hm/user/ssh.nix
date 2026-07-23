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

      matchBlocks = mkMerge [
        {
          "admin" = {
            hostname = "admin";
            user = "root";

            forwardAgent = true;
          };

          "proxmox" = {
            hostname = "proxmox";
            user = "root";

            proxyJump = "admin";
          };

          "nixos-server" = {
            hostname = "nixos-server";
            user = "adam";

            proxyJump = "admin";
            forwardAgent = true;
          };

          "hermes".forwardAgent = true;

          "pangolin" = {
            hostname = "amarek.pl";
            port = 2222;

            user = "ubuntu";
          };
        }

        (mapAttrs (containerName: containerData: {
          hostname = containerData.localAddress;
          user = containerName;

          proxyJump = lib.mkIf (!isServer) "nixos-server";
        }) serverConfig.containers)
      ];
    };
  };
}
