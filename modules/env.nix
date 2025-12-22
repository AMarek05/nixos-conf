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
      PATH = "$PATH:/home/adam/Scripts:/home/adam/.cargo/bin";
      NH_FLAKE = "/home/adam/sys";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
