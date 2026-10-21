# modules/custom/minecraft/default.nix
#
# Minecraft servers as OCI containers. Only one is active at a time: they
# conflict with each other and are ordered against each other, so starting one
# stops the other before it can fail to bind the shared host port.
#
# `mc-manage` switches the active server and records the choice, restored on
# boot.
#
#   imports = [ lib.my.modules.minecraft ];
#   nixosModules.minecraft.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosModules.minecraft;

  names = lib.attrNames cfg.servers;

  # Read from the oci-containers module so the unit names cannot disagree.
  backend = config.virtualisation.oci-containers.backend;

  unitOf = name: "${backend}-${name}";

  dataDirOf =
    name: server: if server.dataDir == null then "${cfg.stateDir}/${name}-data" else server.dataDir;

  conflictsOf = name: map (other: "${unitOf other}.service") (lib.filter (n: n != name) names);

  # `Conflicts=` carries no ordering, and the servers share a host port, so the
  # old one has to be fully stopped before the new one starts. Ordering by
  # name keeps the graph acyclic - mutual `After=` would be a cycle.
  afterOf = name: map (other: "${unitOf other}.service") (lib.filter (n: n < name) names);
in
{
  options.nixosModules.minecraft = {
    enable = lib.mkEnableOption "Minecraft servers running as OCI containers";

    port = lib.mkOption {
      type = lib.types.port;
      default = 25565;
      description = ''
        Port the Minecraft server is published on. All servers share it, since
        only one of them runs at a time.
      '';
    };

    containerPort = lib.mkOption {
      type = lib.types.port;
      default = 25565;
      description = "Port the Minecraft server listens on inside the container.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/minecraft";
      description = ''
        Directory holding the per-server data directories and the file that
        records the active server.
      '';
    };

    activeServerFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.stateDir}/active_server";
      description = ''
        File recording the name of the active server. Read on boot to restore
        the previous selection.
      '';
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              description = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Human readable name of the server, shown by `mc-manage list`.";
              };

              image = lib.mkOption {
                type = lib.types.str;
                description = "OCI image to run the server from.";
              };

              environment = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Environment variables passed to the container.";
              };

              dataDir = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Host directory holding the server's persistent data. Defaults
                  to `<stateDir>/<name>-data`.
                '';
              };

              volumes = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Extra volumes to attach to the container, in `src:dst` form.";
              };
            };
          }
        )
      );
      default = { };
      description = "Minecraft servers to run. Only one of them is active at a time.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      visible = false;
      default = pkgs.callPackage ./package.nix {
        servers = cfg.servers;
        inherit (cfg) activeServerFile;
        inherit backend;
      };
      description = ''
        The `mc-manage` derivation. Pin onto `systemd.path` when the tool must
        be available to a service but not on `$PATH`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = lib.mapAttrs (name: server: {
      inherit (server) image environment;

      serviceName = unitOf name;
      ports = [ "${toString cfg.port}:${toString cfg.containerPort}" ];

      volumes = [
        "${dataDirOf name server}:/data"
      ]
      ++ server.volumes;

      extraOptions = [ "--stop-timeout=120" ];

      # Only the active server runs; the restore unit starts it on boot.
      autoStart = false;
    }) cfg.servers;

    systemd.services =
      (lib.mapAttrs' (
        name: _:
        lib.nameValuePair (unitOf name) {
          conflicts = conflictsOf name;
          after = afterOf name;

          # The servers are long lived; a rebuild must not restart them.
          restartIfChanged = false;

          serviceConfig = {
            TimeoutStopSec = lib.mkForce 130;
          };
        }
      ) cfg.servers)
      // lib.optionalAttrs (names != [ ]) {
        minecraft-active-server = {
          description = "Restore active Minecraft server selection";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "restore-mc" ''
              STATE_FILE=${lib.escapeShellArg cfg.activeServerFile}
              if [ -f "$STATE_FILE" ]; then
                TARGET=$(cat "$STATE_FILE")
                case "$TARGET" in
                  ${lib.concatMapStringsSep "|" (n: lib.escapeShellArg n) names})
                    systemctl start "${backend}-$TARGET.service"
                    ;;
                esac
              fi
            '';
          };
        };
      };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 root root - -"
    ]
    ++ lib.mapAttrsToList (name: server: "d ${dataDirOf name server} 0755 1000 1000 - -") cfg.servers;

    # Publishing a port bypasses the firewall, so it has to be opened here.
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    environment.systemPackages = [ cfg.package ];
  };
}
