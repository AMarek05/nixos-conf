{
  config,
  lib,
  pkgs,
  inputs,
  myLib,
  ...
}:

let
  cfg = config.nixosModules.containers;

  # Sort container names alphabetically to guarantee deterministic IP & UID allocation across rebuilds.
  containerNames = lib.sort (a: b: a < b) (builtins.attrNames cfg.instances);

  # Assign deterministic IP offsets (e.g., index 0 -> .11, index 1 -> .12)
  ipMappings = lib.imap1 (i: name: {
    inherit name;
    ip = "${cfg.subnetPrefix}.${toString (cfg.baseIpOffset + i)}";
  }) containerNames;

  ipMap = builtins.listToAttrs (map (x: lib.nameValuePair x.name x.ip) ipMappings);

  # Assign deterministic per-container index for base UID calculations
  containerIndexMap = builtins.listToAttrs (
    lib.imap0 (i: name: lib.nameValuePair name i) containerNames
  );
in
{
  options.nixosModules.containers = {
    enable = lib.mkEnableOption "Managed systemd-nspawn containers";

    subnetPrefix = lib.mkOption {
      type = lib.types.str;
      default = "192.168.100";
    };

    hostIpSuffix = lib.mkOption {
      type = lib.types.int;
      default = 10;
    };

    baseIpOffset = lib.mkOption {
      type = lib.types.int;
      default = 10;
    };

    uidGidOffsetBase = lib.mkOption {
      type = lib.types.ints.u32;
      default = 100000;
      description = "Starting offset for unprivileged user namespaces.";
    };

    basePath = lib.mkOption {
      type = lib.types.path;
      description = "The directory path to resolve internal container configurations from. Usually ./.";
    };

    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.20.20.5" ];
    };

    sharedModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
    };

    instances = lib.mkOption {
      description = "Attribute set of containers to spin up.";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }: {
            options = {
              # --- Exposed Computed Attributes ---
              shiftedHostUid = lib.mkOption {
                type = lib.types.ints.u32;
                readOnly = true;
                description = "The computed host-side shifted UID for this container's service user.";
              };

              ip = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                description = "The computed static IP assigned to this container.";
              };

              baseUidOffset = lib.mkOption {
                type = lib.types.int;
                readOnly = true;
                description = "The starting UID offset assigned to this container's namespace.";
              };

              # --- Configuration Inputs ---
              internalUid = lib.mkOption {
                type = lib.types.ints.u32;
                description = "Unmapped UID of the service user inside the container.";
              };

              stateDir = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "/var/lib/${name}";
                description = "Bind-mounted state directory.";
              };

              bindMounts = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Attribute set of bind mounts (same syntax as NixOS bindMounts).";
              };

              configFile = lib.mkOption {
                type = lib.types.str;
                default = "${name}.nix";
                description = "Name of the file or directory containing the internal config.";
              };

              ports = lib.mkOption {
                type = lib.types.listOf lib.types.port;
                default = [ ];
                description = "List of ports to open in both firewalls.";
              };

              udpPorts = lib.mkOption {
                type = lib.types.listOf lib.types.port;
                default = [ ];
                description = "List of UDP ports to open in both firewalls.";
              };
            };

            # Automatically compute values accessible elsewhere in your NixOS config
            config = {
              ip = ipMap.${name};
              baseUidOffset = cfg.uidGidOffsetBase + (containerIndexMap.${name} * 65536);
              shiftedHostUid = config.baseUidOffset + config.internalUid;
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure stateDir on the host is created owned by the shifted UID:GID
    systemd.tmpfiles.rules = lib.mapAttrsToList (
      name: instanceCfg:
      if instanceCfg.stateDir != null then
        "d ${instanceCfg.stateDir} 0770 ${toString instanceCfg.shiftedHostUid} ${toString instanceCfg.shiftedHostUid} - -"
      else
        ""
    ) cfg.instances;

    # Generate standard NixOS container definitions
    containers = lib.mapAttrs (
      name: instanceCfg:
      let
        # Combine user bindMounts with the auto-generated stateDir
        allBinds =
          instanceCfg.bindMounts
          // (lib.optionalAttrs (instanceCfg.stateDir != null)) {
            "${instanceCfg.stateDir}" = {
              hostPath = instanceCfg.stateDir;
              isReadOnly = false;
            };
          };

        # Route every bind mount through extraFlags to inject :idmap,norbind
        bindFlags = lib.mapAttrsToList (
          target: mount:
          let
            flag = if mount.isReadOnly or false then "--bind-ro" else "--bind";
          in
          "${flag}=${mount.hostPath}:${target}:idmap,norbind"
        ) allBinds;
      in
      {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "${cfg.subnetPrefix}.${toString cfg.hostIpSuffix}";
        localAddress = instanceCfg.ip;

        # Standard linear private user namespace
        privateUsers = instanceCfg.baseUidOffset;

        # Bypass NixOS default bindMounts schema to use raw nspawn flags with :idmap
        bindMounts = { };
        extraFlags = bindFlags;

        # Thread the resolved IP and host bridge address into the guest config so
        # downstream templates (e.g. open-webui upstream URL) interpolate from
        # this single source of truth rather than hardcoding.
        specialArgs = {
          inherit inputs myLib;
          myIp = instanceCfg.ip;
          hostBridgeAddress = "${cfg.subnetPrefix}.${toString cfg.hostIpSuffix}";
        };

        config = { ... }: {
          imports = cfg.sharedModules ++ [ (cfg.basePath + "/${instanceCfg.configFile}") ];

          nixpkgs.overlays = config.nixpkgs.overlays;

          networking.hostName = name;
          networking.usePredictableInterfaceNames = false;
          networking.nameservers = lib.mkForce cfg.nameservers;

          services.resolved.enable = true;
          networking.useHostResolvConf = lib.mkForce false;
          networking.firewall.allowedTCPPorts = instanceCfg.ports;
          networking.firewall.allowedUDPPorts = instanceCfg.udpPorts;

          # Service user inside the container assumes the unmapped internalUid (default 970)
          users.users."${name}".uid = lib.mkDefault instanceCfg.internalUid;
          users.groups."${name}".gid = lib.mkDefault instanceCfg.internalUid;

          time.timeZone = lib.mkDefault "Europe/Warsaw";
          system.stateVersion = lib.mkDefault "24.11";
        };
      }
    ) cfg.instances;

    users.users = lib.mapAttrs (name: instanceCfg: {
      isSystemUser = true;
      group = name;
      uid = instanceCfg.shiftedHostUid;
    }) cfg.instances;

    users.groups = lib.mapAttrs (name: instanceCfg: {
      gid = instanceCfg.shiftedHostUid;
    }) cfg.instances;

    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens18";
    };

    networking.firewall.trustedInterfaces = [ "ve-+" ];
    networking.firewall.allowedTCPPorts = lib.flatten (
      lib.mapAttrsToList (name: instanceCfg: instanceCfg.ports) cfg.instances
    );
    networking.firewall.allowedUDPPorts = lib.flatten (
      lib.mapAttrsToList (name: instanceCfg: instanceCfg.udpPorts) cfg.instances
    );

    systemd.services = lib.mkMerge (
      map (name: {
        "container@${name}".serviceConfig = {
          TimeoutStopSec = lib.mkForce "15s";
          KillMode = lib.mkForce "mixed";
          ExecStopPost = lib.mkForce [
            "-${pkgs.util-linux}/bin/umount -l /run/systemd/nspawn/unix-export/${name}"
            "-${pkgs.coreutils}/bin/rm -rf /run/systemd/nspawn/unix-export/${name}"
            "-${pkgs.iproute2}/bin/ip link delete ve-${name}"
            "-${pkgs.coreutils}/bin/rm -f /run/systemd/machines/${name}"
          ];
        };
      }) containerNames
    );
  };
}
