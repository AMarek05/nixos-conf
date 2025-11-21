{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.modules.env = {
    enable = lib.mkEnableOption "env";
  };

  config = lib.mkIf config.modules.env.enable {
    home.sessionVariables = {
      SHELL = pkgs.zsh;
      PATH = "$PATH:/home/adam/Scripts";
      TERM = "xterm-256color";
      NH_FLAKE = "/home/adam/sys";
    };
  };
}
