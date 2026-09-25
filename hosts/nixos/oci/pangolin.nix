{
  config,
  pkgs,
  lib,
  ...
}:
{
  users.users.adam.extraGroups = [ "fossorial" ];

  services.pangolin = {
    enable = true;

    package = pkgs.fosrl-pangolin.override { edition = "enterprise"; };

    openFirewall = true;
    baseDomain = "amarek.pl";
    dashboardDomain = "pangolin.amarek.pl";
    letsEncryptEmail = "amarek05@pm.me";
    dnsProvider = "cloudflare";

    dataDir = "/var/lib/pangolin";
    environmentFile = "/etc/nixos/secrets/pangolin.env";

    settings = {
      app = {
        dashboard_url = "https://pangolin.amarek.pl";
        log_level = "info";
        telemetry.anonymous_usage = true;
      };
      gerbil = {
        start_port = 51820;
        base_endpoint = "pangolin.amarek.pl";
      };
      domains.domain1 = {
        base_domain = "amarek.pl";
        prefer_wildcard_cert = true;
      };
      server = {
        cors = {
          origins = [ "https://pangolin.amarek.pl" ];
          methods = [
            "GET"
            "POST"
            "PUT"
            "DELETE"
            "PATCH"
          ];
          allowed_headers = [
            "X-CSRF-Token"
            "Content-Type"
          ];
          credentials = false;
        };
      };
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = false;
        allow_raw_resources = true;
      };
    };
  };

  systemd.services.pangolin = {
    serviceConfig = {
      CapabilityBoundingSet = [
        "CAP_DAC_READ_SEARCH"
        "CAP_NET_BIND_SERVICE"
      ];
      AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
    };
  };

  services.traefik.environmentFiles = [
    config.sops.templates."traefik-cloudflare-env".path
  ];

  services.traefik.staticConfigOptions.entryPoints = {
    tcp-22.address = ":22/tcp";
    web.http.middlewares = [ "custom-errors@file" ];
    websecure.http.middlewares = [ "custom-errors@file" ];
  };

  services.traefik.staticConfigOptions.providers.http.endpoint =
    lib.mkForce "http://127.0.0.1:3001/api/v1/traefik-config";

  services.traefik.dynamicConfigOptions.http = {
    services.int-api-service.loadBalancer.servers = [
      { url = "http://127.0.0.1:3000"; }
    ];

    services.error-pages-svc.loadBalancer = {
      passHostHeader = false;
      servers = [
        { url = "http://127.0.0.1:8081"; }
      ];
    };

    middlewares.custom-errors.errors = {
      status = [ "400-599" ];
      service = "error-pages-svc";
      query = "/{status}.html";
    };

    routers.error-pages-router = {
      rule = "PathRegexp(`^/[0-9]{3}\\.html$`)";
      service = "error-pages-svc";
      priority = 99999;
      entryPoints = [
        "web"
        "websecure"
      ];
    };

    routers.catch-all-fallback = {
      rule = "PathPrefix(`/`)";
      service = "error-pages-svc";
      priority = 1;
      entryPoints = [
        "web"
        "websecure"
      ];
      middlewares = [ "custom-errors@file" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [
    51820
    21820
  ];

  sops.templates."traefik-cloudflare-env" = {
    owner = "traefik";
    group = "fossorial";
    mode = "0440";
    content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare_dns_key"}
    '';
  };

  sops.secrets."cloudflare_dns_key" = {
    sopsFile = ../../../secrets/serv.yaml;
  };

  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  services.crowdsec = {
    enable = true;
    settings = {
      general.api.server.enable = true;
      lapi.credentialsFile = "/var/lib/crowdsec/lapi-credentials.yaml";
    };
    localConfig.acquisitions = [
      {
        source = "file";
        filename = "/var/log/traefik/access.log";
        labels.type = "traefik";
      }
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/crowdsec 0755 crowdsec crowdsec - -"
    "d /etc/nixos/secrets 0755 root root - -"
    "d /var/lib/pangolin/config/letsencrypt 0750 traefik fossorial - -"
    "z /var/lib/pangolin/config/letsencrypt/acme.json 0600 traefik fossorial - -"
  ];

  systemd.services.pangolin-env-init = {
    wantedBy = [ "multi-user.target" ];
    before = [ "pangolin.service" ];
    requiredBy = [ "pangolin.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -e
      f="/etc/nixos/secrets/pangolin.env"

      if [ -f "$f" ]; then 
        exit 0
      fi

      install -d -m 0755 /etc/nixos/secrets
      umask 037
      s=$(head -c 32 /dev/urandom | base64 -w 0)
      printf 'SERVER_SECRET=%s\n' "$s" > "$f"

      chown pangolin:fossorial "$f"
      chmod 0640 "$f"
    '';
  };

  virtualisation.oci-containers.containers.error-pages = {
    image = "ghcr.io/tarampampam/error-pages:3";
    environment.TEMPLATE_NAME = "connection";
    ports = [ "127.0.0.1:8081:8080" ];
  };
}
