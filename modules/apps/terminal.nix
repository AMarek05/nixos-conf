{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.modules.apps.terminal = {
    enable = lib.mkEnableOption "terminal";
  };

  config = lib.mkIf config.modules.apps.terminal.enable {

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
              set -g @tokyo-night-tmux_window_id_style fsquare
            '';
          }
          {
            plugin = pkgs.tmuxPlugins.resurrect;
            extraConfig = ''
              set -g @resurrect-capture-pane-contents 'on'
              set -g @resurrect-processes 'nvim'
            '';
          }
          pkgs.tmuxPlugins.yank
          pkgs.tmuxPlugins.continuum
        ];

        extraConfig = ''
          set -ga terminal-overrides ",xterm-256color:Tc"
          bind \\ split-window -v
          bind v split-window -h

          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          # moving between windows with vim movement keys
          bind -r C-h select-window -t :-
          bind -r C-l select-window -t :+

          # resize panes with vim movement keys
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5
        '';
      };

      ghostty = {
        enable = true;
        settings = {
          theme = "TokyoNight Night";

          window-padding-x = 5;
          window-padding-y = 5;
          window-padding-balance = true;

          font-family = "JetBrainsMono Nerd Font";
          font-style = "JetBrainsMono NF Regular";

          app-notifications = false;
          shell-integration-features = "ssh-terminfo,ssh-env";

          background-opacity = 0.92;
          background-blur = true;
        };
        enableZshIntegration = true;
      };
    };
  };
}
