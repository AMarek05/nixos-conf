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
    home.activation.ensureSshSockets =
      lib.hm.dag.entryAfter [ "writeBoundary" ]
        ''
          mkdir -p $HOME/.ssh/sockets
          chmod 700 $HOME/.ssh/sockets
        '';

    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;

      settings = mkMerge [
        {
          "*" = {
            ControlMaster = "auto";
            ControlPath = "~/.ssh/sockets/%r@%h:%p";
            ControlPersist = "15m";
          };

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

          "nixos-oci" = {
            HostName = "amarek.pl";
            User = "adam";
            Port = 2222;
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
