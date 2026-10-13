# Sunshine wayland screen sharing
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "gaming.sunshine") {
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
