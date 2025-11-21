{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;

      terminal = "xterm-256color";
      shell = "${pkgs.zsh}/bin/zsh";

      sensibleOnTop = true;

      prefix = "C-a";
      keyMode = "vi";
      mouse = true;

      newSession = true;

      plugins = [
        {
          plugin = pkgs.tmuxPlugins.tokyo-night-tmux;
          extraConfig = ''
            set -g @tokyo-night-tmux_date_format DMY
            set -g @tokyo-night-tmux_time_format 24H
            set -g @tokyo-night-tmux_show_battery_widget 0
          '';
        }
        {
          plugin = pkgs.tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-nvim 'session'
          '';
        }
        pkgs.tmuxPlugins.yank
        pkgs.tmuxPlugins.continuum
      ];

      extraConfig = ''
        set -ga terminal-overrides ",xterm-256color:Tc"
      '';
    };

    ghostty = {
      enable = true;
      settings = {
        theme = "TokyoNight Night";
      };
      enableZshIntegration = true;
    };
  };
}
