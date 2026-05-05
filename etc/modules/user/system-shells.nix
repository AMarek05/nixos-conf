# user/system-shells.nix — system-wide shell configuration
{ lib, config }:
let
  cfg = config.modules.user.system-shells;
in
{
  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;

    environment.pathsToLink = [ "/share/zsh/" ];
  };
}
