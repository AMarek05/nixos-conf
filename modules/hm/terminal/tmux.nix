# tmux module — terminal multiplexer configuration
{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.hmModules.terminal.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf config.hmModules.terminal.tmux.enable {
    home.packages = [ pkgs.gitmux ];

    home.file.".config/.gitmux.conf".text = ''
      tmux:
        symbols:
            branch: ' '
            hashprefix: ':'
            revision: ' '
            staged: ' '
            conflict: ' '
            modified: ' '
            untracked: ' '
            stashed: ' '
            clean: ' '
            insertions: ' '
            deletions: ' '
        styles:
            clear: '#[fg=#cdd6f4]'
            state: '#[fg=#f38ba8,bold]'
            branch: '#[fg=#a6e3a1,bold]'
            remote: '#[fg=#89b4fa]'
            staged: '#[fg=#a6e3a1,bold]'
            conflict: '#[fg=#f38ba8,bold]'
            modified: '#[fg=#f9e2af,bold]'
            untracked: '#[fg=#cba6f7,bold]'
            stashed: '#[fg=#89b4fa,bold]'
            clean: '#[fg=#a6e3a1,bold]'
            insertions: '#[fg=#a6e3a1,bold]'
            deletions: '#[fg=#f38ba8,bold]'
        layout: [branch, divergence, " - ", flags, " ", stats]
        options:
          branch_max_len: 0
    '';

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
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor 'mocha'
            set -g status-interval 3

            set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
            set -g @catppuccin_status_background "#1e1e2e"

            set -g @catppuccin_status_left_separator ""
            set -g @catppuccin_status_right_separator ""

            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_default_text " #{b:pane_current_command}"
            set -g @catppuccin_window_current_text " #{b:pane_current_command}"
            set -g @catppuccin_window_current_color "#cba6f7"

            set -g @catppuccin_session_color "#a6e3a1"

            set -g status-left-length 100
            set -g status-right-length 100
            set -g status-left ""
            set -g status-right ""

            set -ga status-left "#{?client_prefix,#[fg=#f9e2af bg=#1e1e2e]#[bg=#f9e2af fg=#11111b bold]󱐋#[fg=#f9e2af bg=#1e1e2e] #[fg=#cdd6f4 bg=#1e1e2e],}"

            set -ga status-left "#[fg=#a6e3a1 bg=#1e1e2e]#[fg=#11111b bg=#a6e3a1 bold] #[fg=#cdd6f4 bg=#313244] #S#[fg=#313244 bg=#1e1e2e] "

            set -g @catppuccin_date_time_text " %b %d, %H:%M"

            set -ga status-right "#(gitmux -cfg $HOME/.config/.gitmux.conf '#{pane_current_path}')"
            set -ga status-right " "
            set -ga status-right "#{E:@catppuccin_status_directory}"
            set -ga status-right "#{E:@catppuccin_status_date_time}"
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
        bind-key C-m if-shell "tmux has-session -t main 2>/dev/null" \
          "switch-client -t main" \
          "new-session -d -s main; switch-client -t main"

        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+

        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        set-option -g detach-on-destroy off

        new-session -d -s main
        new-session -d -s servers
      '';
    };
  };
}
