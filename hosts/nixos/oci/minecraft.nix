# Minecraft servers on the OCI host.
#
# The server declarations live here, the machinery behind them lives in
# `modules/custom/minecraft`. Only one server runs at a time — they conflict
# with each other — so switching is done with `mc-manage`.
{
  lib,
  ...
}:
{
  imports = [ lib.my.modules.minecraft ];

  nixosModules.minecraft = {
    enable = true;

    servers = {
      gtnh = {
        description = "GTNH 2.8.4";
        image = "itzg/minecraft-server:java25";
        environment = {
          TYPE = "GTNH";
          GTNH_PACK_VERSION = "2.8.4";
          MEMORY = "8G";
          EULA = "TRUE";
          RCON_PASSWORD = "pass";
        };
      };

      startech = {
        description = "StarTech 1.20.1";
        image = "itzg/minecraft-server:java17";
        environment = {
          TYPE = "FORGE";
          VERSION = "1.20.1";
          FORGE_VERSION = "47.4.0";
          MEMORY = "8G";
          DIFFICULTY = "peaceful";
          OPS = "atrys14";
          ENABLE_WHITELIST = "TRUE";
          WHITELIST = "atrys14";
          EULA = "TRUE";
          RCON_PASSWORD = "pass";
        };
      };
    };
  };
}
