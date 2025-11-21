{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;

      terminal = "xterm-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      shortcut = "a";
      newSession = true;
    };

    ghostty = {
      enable = true;
    };
  };
}
