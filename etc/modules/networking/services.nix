# networking/services.nix — VPN services (Mullvad, Tailscale)
{ pkgs, lib, config }:
let
  cfg = config.modules.networking.services;
in
{
  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    # Enable tailscale
    services.tailscale.enable = false;

    # Disable systemd-userdb/homed (not needed)
    systemd.services."systemd-userdb".enable = false;
    systemd.services."systemd-homed".enable = false;
    systemd.sockets."systemd-userdb".enable = false;
  };
}
