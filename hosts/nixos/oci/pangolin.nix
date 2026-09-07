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

  # Same SOPS key path as nixos-server: dedicated file, provisioned at install time.
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
  ];

  # Generate pangolin.env on first boot if absent. Stable across
  # rebuilds; replaced if you provision a real one via --extra-files.
  systemd.services.pangolin-env-init = {
    wantedBy = [ "multi-user.target" ];
    before = [ "pangolin.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/sh -c ''f=/etc/nixos/secrets/pangolin.env; test -f \$f || { umask 037; install -d -m 0755 /etc/nixos/secrets; s=\$(head -c 32 /dev/urandom | base64 -w 0); echo SERVER_SECRET=\$s > \$f; chown pangolin:fossorial \$f; chmod 0640 \$f; }''";
    };
  };

  virtualisation.oci-containers.containers.error-pages = {
    image = "ghcr.io/tarampampam/error-pages:3";
    environment.TEMPLATE_NAME = "connection";
    ports = [ "127.0.0.1:8081:8080" ];
  };
}
