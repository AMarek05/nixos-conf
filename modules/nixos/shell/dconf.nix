# modules/nixos/shell/dconf.nix — enable dconf (GNOME settings storage).
{ config, lib, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "shell.dconf") {
    programs.dconf.enable = true;
  };
}
