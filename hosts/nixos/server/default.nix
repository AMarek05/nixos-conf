{ config, lib, ... }:
{
  imports = [
    ./graphics.nix
  ];

  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."cloudflare_dns_key" = {
    sopsFile = ../../../secrets/serv.yaml;
    owner = "acme";
    group = "acme";
    mode = "0400";
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

    port = 8000;
  };

  services.plex = {
    enable = true;

    openFirewall = true;
  };

  services.caddy = {
    enable = true;

    virtualHosts."st.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8000
      '';
    };
    virtualHosts."plex.amarek.org" = {
      useACMEHost = "amarek.org";
      extraConfig = ''
        reverse_proxy 127.0.0.1:32400
      '';
    };
  };
}
