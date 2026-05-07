# tmux module — terminal multiplexer configuration
{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.modules.terminal.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf config.modules.terminal.tmux.enable {
    programs.tmux = {
      enable = true;

      terminal = "xterm-ghostty";
      shell = "${pkgs.zsh}/bin/zsh";

      sensibleOnTop = true;

      prefix = "C-a";
      keyMode = "vi";
      mouse = true;
      disableConfirmationPrompt = true;

      escapeTime = 0;
      baseIndex = 1;

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
        bind \\ split-window -v
        bind v split-window -h

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind f popup -E -w 80% -h 80% "forge pick"

        bind-key C-q run-shell "tmux switch-client -t main && tmux kill-session -t \"#S\""

        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+

        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        set-option -g detach-on-destroy off

        new-session -d -s servers
      '';
    };
  };
}
