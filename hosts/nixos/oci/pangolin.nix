{ config, ... }:
{
  services.pangolin = {
    enable = true;
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
          methods = [ "GET" "POST" "PUT" "DELETE" "PATCH" ];
          allowed_headers = [ "X-CSRF-Token" "Content-Type" ];
          credentials = false;
        };
        maxmind_db_path = "./config/GeoLite2-Country.mmdb";
      };
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = false;
        allow_raw_resources = true;
      };
    };
  };

  services.traefik.environmentFiles = [
    config.sops.templates."traefik-cloudflare-env".path
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

  services.crowdsec = {
    enable = true;
    settings = {
      general.api.server.enable = true;
      lapi.credentialsFile = "/var/lib/crowdsec/lapi-credentials.yaml";
    };
  };

  services.crowdsec.firewallBouncer = {
    enable = true;
    settings = {
      mode = "live";
      updateFrequency = "10s";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/crowdsec 0755 crowdsec crowdsec - -"
  ];

  virtualisation.oci-containers.containers.error-pages = {
    image = "ghcr.io/tarampampam/error-pages:3";
    environment.TEMPLATE_NAME = "connection";
    ports = [ "127.0.0.1:8080:8080" ];
    restart = "always";
  };
}
