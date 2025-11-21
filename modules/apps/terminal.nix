{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;

      terminal = "xterm-256color";
      shell = "${pkgs.zsh}/bin/zsh";

      prefix = "C-a";
      newSession = true;
    };

    ghostty = {
      enable = true;
      settings = {
        theme = "TokyoNight Night";
      };
    };
  };
}
