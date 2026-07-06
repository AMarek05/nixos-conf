# man module — colorized manpages via bat coloring
{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf (config.hmModules.terminal.enable && config.hmModules.terminal.man.enable) {
    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
      MANROFFOPT = "-c";
    };
  };
}
