{
  config,
  lib,
  inputs,
  pkgs,
  myLib,
  ...
}:
let
  commonAssign = lib.mapAttrs (
    name: specificConfig:
    specificConfig
    // {
      group = name;
      isSystemUser = true;
    }
  );

  hermes-address = config.containers.hermes.localAddress;

  vwcfg = config.services.vaultwarden.config;
in
{
  imports = [
    ./graphics.nix
    ./attic.nix
    ./vaultwarden.nix
    ./reader.nix

    "${inputs.self}/lib/containers.nix"

    # static container guest user declaration module
    {
      users = {
        users = commonAssign {
          hermes.uid = 970;
          openclaw.uid = 968;
          runner.uid = 971;
        };

        groups = {
          openclaw.gid = 968;
          hermes.gid = 970;
          runner.gid = 971;
        };
      };
    }
  ];

  nixosModules.containers = {
    enable = true;
    basePath = ./containers;

    sharedModules = [
      ./containers/common.nix

      inputs.sops-nix.nixosModules.sops
    ];

    instances = {
      "hermes" = {
        configFile = "hermes/default.nix";

        bindMounts = {
          "/var/lib/sops-nix/age_key" = {
            hostPath = "/var/lib/sops-nix/age_key";
            isReadOnly = true;
          };
        };
      };

      "runner" = {
        bindMounts = {
          "/var/lib/sops-nix/age_key" = {
            hostPath = "/var/lib/sops-nix/age_key";
            isReadOnly = true;
          };
        };
      };
    };
  };

  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."cloudflare_dns_key" = {
    sopsFile = ../../../secrets/serv.yaml;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  sops.secrets."newt_env" = {
    sopsFile = ../../../secrets/serv.yaml;

    owner = "adam";
    group = "adam";
    mode = "0444";
  };

  fileSystems."/media" = {
    device = "/dev/disk/by-uuid/6ec56f8e-689b-42fc-8a70-108d77fdeba3";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/7993d92d-68b8-4b31-8397-c3ed230c1715";
    fsType = "ext4";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "amarek05@pm.me";

    certs."amarek.pl" = {
      domain = "*.amarek.pl";
      extraDomainNames = [ "amarek.pl" ];
      dnsProvider = "cloudflare";

      credentialFiles = {
        "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare_dns_key".path;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    2222
    18789
    8642
  ];

  networking.firewall.allowedUDPPorts = [
    51820
    21820
  ];

  nixpkgs.overlays = [
    (final: prev: {
      sillytavern = prev.sillytavern.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/lib/node_modules/sillytavern/public/scripts/extensions/third-party
          # Fix: add cache headers to express.static so browsers dont re-download
          # hundreds of MB of JS/CSS/avatars on every reload. The express.static
          # call had {} (max-age=0) while only the HTML entry point was cache-busted.
          sed -i "s|app.use(express.static(path.join(serverDirectory, 'public'), {}));|app.use(express.static(path.join(serverDirectory, 'public'), { maxAge: '7d', etag: true }));|" \
            $out/lib/node_modules/sillytavern/src/server-main.js
        '';
      });
    })
  ];

  services.sillytavern = {
    enable = true;
    configFile = "/var/lib/SillyTavern/config.yaml.bak";

    port = 8000;
  };

  services.newt = {
    enable = true;

    environmentFile = config.sops.secrets."newt_env".path;
  };

  services.jellyfin = {
    enable = true;

    openFirewall = true;

    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };

    forceEncodingConfig = true;

    transcoding = {
      enableToneMapping = true;
      enableHardwareEncoding = true;

      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        vp9 = true;
        av1 = true;
      };

      hardwareEncodingCodecs = {
        hevc = true;
        av1 = false;
      };
    };
  };

  services.qbittorrent = {
    enable = true;

    webuiPort = 8181;
    openFirewall = true;
  };

  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];

  users.users.sonarr.extraGroups = [ "jellyfin" ];
  users.users.radarr.extraGroups = [ "jellyfin" ];
  users.users.bazarr.extraGroups = [ "jellyfin" ];

  users.users.adam.extraGroups = [
    "jellyfin"
    "sillytavern"
    "hermes"
    "openclaw"
  ];

  services.bazarr = {
    enable = true;

    openFirewall = true;
  };

  services.sonarr = {
    enable = true;

    openFirewall = true;
  };

  services.radarr = {
    enable = true;

    openFirewall = true;
  };

  services.forgejo = {
    enable = true;

    user = "git";
    group = "git";

    lfs.enable = true;

    database = {
      type = "postgres";
      createDatabase = true;

      user = "git";
      name = "git";

      socket = "/run/postgresql";
    };

    settings.server = {
      DOMAIN = "git.amarek.pl";
      ROOT_URL = "https://git.amarek.pl/";

      START_SSH_SERVER = true;

      SSH_LISTEN_PORT = 2222;

      SSH_PORT = 22;
      SSH_DOMAIN = "amarek.pl";
    };

    settings.repository.ENABLE_PUSH_CREATE_USER = true;

    settings."repository.signing" = {
      FORMAT = "ssh";
      SIGNING_KEY = "/var/lib/forgejo/ssh-signing-key.pub";
      SIGNING_NAME = "Forgejo";
      SIGNING_EMAIL = "noreply@amarek.pl";

      INITIAL_COMMIT = "always";
      WIKI = "always";
      CRUD_ACTIONS = "always";
      MERGES = "always";
    };
  };

  users.users.git = {
    home = config.services.forgejo.stateDir;
    useDefaultShell = true;
    group = "git";
    isSystemUser = true;
  };

  users.groups.git = { };

  services.caddy = {
    enable = true;

    virtualHosts."st.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        @thumbnail path /thumbnail*
        header @thumbnail Cache-Control "public, max-age=3600"

        reverse_proxy 127.0.0.1:8000 {
          transport http {
            keepalive 5s
            versions 2 1.1
          }
        }
      '';
    };

    virtualHosts."jellyfin.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8096
      '';
    };

    virtualHosts."qbit.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.qbittorrent.webuiPort}
      '';
    };

    virtualHosts."git.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };

    virtualHosts."hermes.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy ${hermes-address}:8642
      '';
    };

    virtualHosts."webui.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy ${hermes-address}:8080
      '';
    };

    virtualHosts."vault.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy ${vwcfg.ROCKET_ADDRESS}:${toString vwcfg.ROCKET_PORT}
      '';
    };
  };
}
