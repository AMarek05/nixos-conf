# services/flatpak.nix
{ config, lib }:
let
  cfg = config.modules.services.flatpak;
in
{
  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
