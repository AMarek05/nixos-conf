{
  config,
  inputs,
  lib,
  ...
}:
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
    "d /media/manga 0775 kapowarr manga - -"
    "d /media/manga/downloads 0775 kapowarr manga - -"
    "d /media/manga/library 0775 kapowarr manga - -"
    "d /var/lib/kaizoku/config 0775 972 manga - -"
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
    containers.kaizoku = {
      image = "ghcr.io/oae/kaizoku:latest";

      # Maps the host machine's IP to 'host.containers.internal' inside the container
      extraOptions = [ "--add-host=host.containers.internal:host-gateway" ];

      # Map your desired host port (3010) to Kaizoku's hardcoded internal port (3000)
      ports = [ "127.0.0.1:3010:3000" ];

      environment = {
        DATABASE_URL = "postgresql://kaizoku@localhost/kaizoku?host=/run/postgresql";
        REDIS_HOST = "host.containers.internal"; # Point to the NixOS host
        REDIS_PORT = "6379";
        PUID = "972";
        PGID = "972";
        TZ = "Europe/Warsaw";
      };
      volumes = [
        "/var/lib/kaizoku/config:/config"
        "/media/manga/library:/data"
        "/run/postgresql:/run/postgresql:rw"
      ];
    };
  };

  services.postgresql = {
    ensureDatabases = [ "kaizoku" ];
    ensureUsers = [
      {
        name = "kaizoku";
        ensureDBOwnership = true;
      }
    ];
    # 'trust' local socket connections specifically for this app
    # The first rule that matches takes precedence, so we put it at the top
    authentication = lib.mkBefore ''
      # TYPE  DATABASE  USER     ADDRESS  METHOD
      local   kaizoku   kaizoku           trust
    '';
  };

  services.redis.servers.kaizoku = {
    enable = true;
    port = 6379;
    bind = "0.0.0.0";
    settings = {
      "protected-mode" = "no";
    };
  };

  # open internal firewall for reddis
  networking.firewall.interfaces."podman+".allowedTCPPorts = [ 6379 ];

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
        reverse_proxy 127.0.0.1:3010
      '';
    };
  };
}
