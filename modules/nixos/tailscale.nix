{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixosModules.tailscale;
in
{
  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";

      extraUpFlags = [ "--accept-routes" ];
    };

    environment.systemPackages = with pkgs; [ tailscale ];
  };
}
