{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.nixosModules.containers;

  # Sort the container names alphabetically to guarantee deterministic IP assignment across rebuilds.
  containerNames = lib.sort (a: b: a < b) (builtins.attrNames cfg.instances);

  # Assign IP offsets based on the sorted index (e.g., index 0 -> .11, index 1 -> .12)
  ipMappings = lib.imap1 (i: name: {
    inherit name;
    ip = "${cfg.subnetPrefix}.${toString (cfg.baseIpOffset + i)}";
  }) containerNames;

  # Convert the list back into an easily queryable attribute set
  ipMap = builtins.listToAttrs (map (x: lib.nameValuePair x.name x.ip) ipMappings);
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
          { name, ... }: {
            options = {
              bindMounts = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };

              configFile = lib.mkOption {
                type = lib.types.str;
                default = name; # Defaults to assuming the file/folder shares the container's name
                description = "Name of the file or directory containing the internal config (e.g., 'hermes' or 'openclaw.nix')";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Generate the standard NixOS container definitions
    containers = lib.mapAttrs (name: instanceCfg: {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "${cfg.subnetPrefix}.${toString cfg.hostIpSuffix}";
      localAddress = ipMap.${name};

      specialArgs = { inherit inputs; };
      bindMounts = instanceCfg.bindMounts;

      config = { ... }: {
        imports = cfg.sharedModules ++ [ (cfg.basePath + "/${instanceCfg.configFile}") ];

        networking.hostName = name;
        networking.usePredictableInterfaceNames = false;
        networking.interfaces.eth.ipv4.addresses = [
          {
            address = ipMap.${name};
            prefixLength = 24;
          }
        ];

        networking.defaultGateway = "${cfg.subnetPrefix}.${toString cfg.hostIpSuffix}";
        networking.nameservers = lib.mkForce cfg.nameservers;

        services.resolved.enable = true;
        networking.useHostResolvConf = lib.mkForce false;

        # Standard baseline inherited from the host structure
        time.timeZone = lib.mkDefault "Europe/Warsaw";
        system.stateVersion = lib.mkDefault "24.11";
      };
    }) cfg.instances;

    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens18";
    };

    # Generate the systemd service workarounds for each container
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
