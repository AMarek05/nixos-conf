# modules/nixos/shell/zsh.nix — enable zsh as a system shell.
{ config, lib, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "shell.zsh") {
    programs.zsh.enable = true;
  };
}
