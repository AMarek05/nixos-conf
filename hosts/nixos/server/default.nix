{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./graphics.nix
  ];

  # ── Container host-side config ────────────────────────────────────────────────
  /*
    containers.openclaw = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";

      specialArgs = { inherit inputs; };

      config =
        {
          ...
        }:
        {
          imports = [ ./openclaw.nix ];
        };

      bindMounts = {
        "/var/lib/sops-nix/age_key" = {
          hostPath = "/var/lib/sops-nix/age_key";
          isReadOnly = true;
        };
        "/var/lib/openclaw/workspace" = {
          hostPath = "/var/lib/openclaw/workspace";
          isReadOnly = false;
        };
      };
    };
  */

  containers.hermes = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.12";

    specialArgs = { inherit inputs; };

    config =
      {
        ...
      }:
      {
        imports = [ ./hermes ];
      };

    bindMounts = {
      "/var/lib/sops-nix/age_key" = {
        hostPath = "/var/lib/sops-nix/age_key";
        isReadOnly = true;
      };
      "/var/lib/hermes" = {
        hostPath = "/var/lib/hermes";
        isReadOnly = false;
      };
    };
  };

  systemd.services."container@openclaw".serviceConfig = {
    TimeoutStopSec = lib.mkForce "15s";
    KillMode = lib.mkForce "mixed";
    ExecStopPost = lib.mkForce [
      "-${pkgs.util-linux}/bin/umount -l /run/systemd/nspawn/unix-export/openclaw"
      "-${pkgs.coreutils}/bin/rm -rf /run/systemd/nspawn/unix-export/openclaw"
      "-${pkgs.iproute2}/bin/ip link delete ve-openclaw"
      "-${pkgs.coreutils}/bin/rm -f /run/systemd/machines/openclaw"
    ];
  };

  systemd.services."container@hermes".serviceConfig = {
    TimeoutStopSec = lib.mkForce "15s";
    KillMode = lib.mkForce "mixed";
    ExecStopPost = lib.mkForce [
      "-${pkgs.util-linux}/bin/umount -l /run/systemd/nspawn/unix-export/hermes"
      "-${pkgs.coreutils}/bin/rm -rf /run/systemd/nspawn/unix-export/hermes"
      "-${pkgs.iproute2}/bin/ip link delete ve-hermes"
      "-${pkgs.coreutils}/bin/rm -f /run/systemd/machines/hermes"
    ];
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens18";
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

  security.acme = {
    acceptTerms = true;
    defaults.email = "amarek05@pm.me";

    certs."amarek.org" = {
      domain = "*.amarek.org";
      extraDomainNames = [ "amarek.org" ];
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

    webuiPort = 8080;

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

  users.groups.hermes.gid = 970;
  users.groups.openclaw.gid = 968;

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

    settings.server = {
      DOMAIN = "git.amarek.org";
      ROOT_URL = "https://git.amarek.org/";

      START_SSH_SERVER = true;

      SSH_LISTEN_PORT = 2222;

      SSH_PORT = 22;
      SSH_DOMAIN = "amarek.org";
    };

    settings.repository.ENABLE_PUSH_CREATE_USER = true;
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

    virtualHosts."st.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8000
      '';
    };

    virtualHosts."jellyfin.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8096
      '';
    };

    virtualHosts."qbit.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };
    virtualHosts."git.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };
    virtualHosts."openclaw.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 192.168.100.11:18789
      '';
    };

    virtualHosts."hermes.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 192.168.100.12:8642
      '';
    };

    virtualHosts."webui.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 192.168.100.12:8080
      '';
    };
  };
}
