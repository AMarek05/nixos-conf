# man module — colorized manpages via bat coloring
{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.hmModules.terminal.man = {
    enable = lib.mkEnableOption "Enable man config";
  };

  config = lib.mkIf config.hmModules.terminal.man.enable {
    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
      MANROFFOPT = "-c";
    };
  };
}
