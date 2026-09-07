# modules/nixos/shell/dconf.nix — enable dconf (GNOME settings storage).
{ config, lib, ... }:
{
  config = lib.mkIf (config.nixosModules.shell.enable && config.nixosModules.shell.dconf.enable) {
    programs.dconf.enable = true;
  };
}
