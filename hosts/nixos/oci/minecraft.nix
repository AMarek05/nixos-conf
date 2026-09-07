{ pkgs, lib, ... }:
{
  virtualisation.oci-containers.containers.gtnh = {
    image = "itzg/minecraft-server:java25";
    environment = {
      TYPE = "GTNH";
      GTNH_PACK_VERSION = "2.8.4";
      MEMORY = "8G";
      EULA = "TRUE";
      RCON_PASSWORD = "pass";
    };
    ports = [ "25575:25565" ];
    volumes = [
      "/var/lib/minecraft/gtnh-data:/data"
    ];
    autoStart = false;
  };

  virtualisation.oci-containers.containers.startech = {
    image = "itzg/minecraft-server:java17";
    environment = {
      TYPE = "FORGE";
      VERSION = "1.20.1";
      MEMORY = "8G";
      DIFFICULTY = "peaceful";
      OPS = "atrys14";
      ENABLE_WHITELIST = "TRUE";
      WHITELIST = "atrys14";
      EULA = "TRUE";
      RCON_PASSWORD = "pass";
    };
    ports = [ "25565:25565" ];
    volumes = [
      "/var/lib/minecraft/startech-data:/data"
    ];
    autoStart = false;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft 0755 root root - -"
    "d /var/lib/minecraft/gtnh-data 0755 1000 1000 - -"
    "d /var/lib/minecraft/startech-data 0755 1000 1000 - -"
  ];
}
