# man module — colorized manpages via bat coloring
{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "terminal.man") {
    home.sessionVariables = {
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
      MANROFFOPT = "-c";
    };
  };
}
