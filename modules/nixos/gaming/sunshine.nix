# Sunshine wayland screen sharing
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf (config.nixosModules.gaming.enable && config.nixosModules.gaming.sunshine.enable)
      {
        services.sunshine = {
          enable = true;

          openFirewall = true;
          autoStart = false;
        };

        environment.systemPackages = with pkgs; [ moonlight-qt ];

        users.users.adam.extraGroups = [
          "input"
          "video"
        ];
      };
}
