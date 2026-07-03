# modules/nixos/shell/zsh.nix — enable zsh as a system shell.
{
  config,
  lib,
  ...
}:
let
  cfgParent = config.nixosModules.shell;
in
{
  options.nixosModules.shell.zsh.enable = lib.mkEnableOption "zsh";

  config = lib.mkIf (cfgParent.enable && config.nixosModules.shell.zsh.enable) {
    programs.zsh.enable = true;
  };
}
