# Sunshine wayland screen sharing
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixosModules.sunshine = {
    enable = lib.mkEnableOption "Sunshine wayland screen sharing";
  };

  config = lib.mkIf config.nixosModules.sunshine.enable {
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
