{
  programs.nvf.settings.vim = {
    ui = {
      borders.enable = true;
      illuminate.enable = true;

      visuals.nvim-web-devicons.enable = true;

      treesitter.context = {
        enable = true;
        setupOpts = {
          maxLines = 5;
          multiline_threshold = 1;
          trim_scope = "outer";
          mode = "cursor";
        };
      };


      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };
      noice.enable = true;
      noice.setupOpts = {
        cmdline.format = {
          filter = {
            pattern = "^:%s*!"; # Detects :!
            icon = ""; # Change this to any icon you want
            lang = "bash"; # Force Bash syntax highlighting

            # Optional: changing the title of the input box
            title = " Shell ";
          };
          routes = [
            {
              view = "popup";
              filter = {
                event = "msg_show";
                kind = "shell_out";
                find = ".*"; # Catch all output text
              };
              opts = {
                persistent = true; # if you want it to stay until you close it manually
              };
            }
            {
              filter = {
                event = "notify";
                find = "require%('lspconfig'%)";
              };
              opts = {
                skip = true;
              };
            }
          ];
        };
      };
    };

    statusline.lualine = {
      enable = true;
      setupOpts = {
        options.theme = "tokyonight";
      };
    };

    dashboard.alpha.enable = true;
  };
}
