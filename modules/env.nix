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
      SHELL = "${pkgs.zsh}/bin/zsh";
      NH_FLAKE = "/home/adam/sys";
      EDITOR = "nvim";
      VISUAL = "nvim";
      QS_ICON_THEME = "Dracula";
    };
  };
}
