{ config, lib, ... }:
{

  sops.secrets."cloudflare_dns_key" = {
    sopsFile = ../../../secrets/serv.yaml;
    owner = "acme";
    group = "acme";
    mode = 0400;
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

  services.sillytavern = {
    enable = true;

    port = 8000;
  };

  services.caddy = {
    enable = true;

    virtualHosts."st.amarek.org".extraConfig = ''
      reverse_proxy localhost:8000
    '';
    virtualHosts."plex.amarek.org".extraConfig = ''
      reverse_proxy localhost:32400
    '';
  };

  services.plex = {
    enable = true;

    openFirewall = true;
  };
}
