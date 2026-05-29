{ config, lib, ... }:
{
  imports = [
    ./graphics.nix
  ];

  # ── Container host-side config ────────────────────────────────────────────────
  containers.openclaw = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";

    config = { config, pkgs, inputs, ... }: {
      imports = [ ./openclaw.nix ];
    };

    forwardPorts = [
      {
        containerPort = 18789;
        hostPort = 18789;
        protocol = "tcp";
      }
    ];

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

  services.plex = {
    enable = true;

    openFirewall = true;
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

    settings.server.DOMAIN = "git.amarek.org";
    settings.server.ROOT_URL = "https://git.amarek.org/";
  };

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
  };
}
