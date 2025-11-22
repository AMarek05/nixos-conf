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
      disableConfirmationPrompt = true;

      escapeTime = 0;
      baseIndex = 1;

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
            set -g @resurrect-processes 'nvim'
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

        window-padding-x = 10;
        window-padding-y = 10;
        window-padding-balance = true;
      };
      enableZshIntegration = true;
    };
  };
}
