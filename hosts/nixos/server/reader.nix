{ config, inputs, ... }:
{
  sops.secrets."kavita-token" = {
    sopsFile = inputs.self + "/secrets/serv.yaml";
    owner = "kavita";
    group = "manga";

    mode = "440";
  };

  # ── 1. Users, Groups, & Permissions ─────────────────────────────────────
  users.groups.manga.gid = 972;

  users.users.kapowarr = {
    isSystemUser = true;
    group = "manga";
    uid = 972;
  };

  users.users.adam.extraGroups = [ "manga" ];

  # Kavita runs under its own 'kavita' user automatically.
  # We just add it to our shared 'manga' group so it can read what Kapowarr downloads.
  users.users.kavita.extraGroups = [ "manga" ];

  # Ensure the host directories exist with the correct permissions before services start
  systemd.tmpfiles.rules = [
    "d /var/lib/kapowarr/db 0775 kapowarr manga - -"
    "d /media/manga 0775 kapowarr manga - -"
    "d /media/manga/downloads 0775 kapowarr manga - -"
    "d /media/manga/library 0775 kapowarr manga - -"
  ];

  # ── 2. Kavita (The Reader) ──────────────────────────────────────────────
  services.kavita = {
    enable = true;

    tokenKeyFile = config.sops.secrets."kavita-token".path;

    settings = {
      Port = 5000;
      IpAddresses = "127.0.0.1";
    };
  };

  virtualisation.podman.enable = true;

  # ── 3. Kapowarr (The Downloader) ────────────────────────────────────────
  virtualisation.oci-containers = {
    backend = "podman";

    containers.kapowarr = {
      image = "docker.io/mrcas/kapowarr:latest";
      ports = [ "127.0.0.1:5656:5656" ];
      volumes = [
        "/var/lib/kapowarr/db:/app/db"
        "/media/manga/downloads:/app/temp_downloads"
        "/media/manga/library:/comics"
      ];
      environment = {
        PUID = "972";
        PGID = "972";
        TZ = "Europe/Warsaw"; # Matching your existing configuration
      };
    };
  };

  # ── 4. Caddy Reverse Proxy ──────────────────────────────────────────────
  services.caddy.virtualHosts = {
    "reader.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy 127.0.0.1:5000
      '';
    };

    "manga.amarek.pl" = {
      useACMEHost = "amarek.pl";
      extraConfig = ''
        reverse_proxy 127.0.0.1:5656
      '';
    };
  };
}
