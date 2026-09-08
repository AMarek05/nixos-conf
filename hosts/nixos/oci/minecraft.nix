{ pkgs, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [ 25565 ];

  virtualisation.oci-containers.containers.gtnh = {
    image = "itzg/minecraft-server:java25";
    environment = {
      TYPE = "GTNH";
      GTNH_PACK_VERSION = "2.8.4";
      MEMORY = "8G";
      EULA = "TRUE";
      RCON_PASSWORD = "pass";
    };
    ports = [ "25565:25565" ];
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

  systemd.services."podman-gtnh".unitConfig.Conflicts = [ "podman-startech.service" ];
  systemd.services."podman-startech".unitConfig.Conflicts = [ "podman-gtnh.service" ];

  systemd.services."podman-gtnh".restartIfChanged = false;
  systemd.services."podman-startech".restartIfChanged = false;

  # Persistent state restorer on boot / rebuild
  systemd.services.minecraft-active-server = {
    description = "Restore active Minecraft server selection";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "restore-mc" ''
        STATE_FILE="/var/lib/minecraft/active_server"
        if [ -f "$STATE_FILE" ]; then
          TARGET=$(cat "$STATE_FILE")
          if [ "$TARGET" = "gtnh" ] || [ "$TARGET" = "startech" ]; then
            systemctl start "podman-$TARGET.service"
          fi
        fi
      '';
    };
  };

  # CLI helper tool to switch cleanly
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mc-switch" ''
      case "$1" in
        gtnh|startech)
          echo "Switching active server to $1..."
          echo "$1" > /var/lib/minecraft/active_server
          systemctl stop podman-gtnh podman-startech
          systemctl start "podman-$1"
          ;;
        status)
          echo "Active recorded: $(cat /var/lib/minecraft/active_server 2>/dev/null || echo 'None')"

          echo -e "\nService status:"
          for serv in gtnh startech; do
            echo -n "$serv: "
            systemctl is-active "podman-$serv"
          done
          ;;
        *)
          echo "Usage: sudo mc-switch [gtnh|startech|status]"
          exit 1
          ;;
      esac
    '')
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft 0755 root root - -"
    "d /var/lib/minecraft/gtnh-data 0755 1000 1000 - -"
    "d /var/lib/minecraft/startech-data 0755 1000 1000 - -"
  ];
}
