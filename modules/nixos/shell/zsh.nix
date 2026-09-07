# modules/nixos/shell/zsh.nix — enable zsh as a system shell.
{ config, lib, ... }:
{
  config = lib.mkIf (config.nixosModules.shell.enable && config.nixosModules.shell.zsh.enable) {
    programs.zsh.enable = true;
  };
}
