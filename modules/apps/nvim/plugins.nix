{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    extraPlugins = {
      nvim-lastplace = {
        package = pkgs.vimPlugins.nvim-lastplace;
        setup = ''
          require("nvim-lastplace").setup {}
        '';
      };
    };

    binds.whichKey.enable = true;
    utility.sleuth.enable = true;
    comments.comment-nvim.enable = true;

    visuals.nvim-web-devicons.enable = true;

    autopairs.nvim-autopairs.enable = true;

    lsp = {
      enable = true;

      servers = {
        nixd.enable = true;
      };

      formatOnSave = true;
      inlayHints.enable = true;

      lspsaga = {
        enable = true;
        setupOpts = {
          lightbulb = {
            enable = false;
            enable_in_insert = false;
            sign = false;
            virtual_test = false;
          };
        };
      };

      mappings = {
        format = "<leader>lf";
        goToDefinition = "gd";
        hover = "K";

        listImplementations = "<leader>li";

        nextDiagnostic = "g]";
        previousDiagnostic = "g[";
        openDiagnosticFloat = "<leader>d";

        renameSymbol = "<leader>rn";
      };
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;

      nix = {
        enable = true;
        format.type = "nixfmt";
      };
    };

    telescope = {
      enable = true;

      extensions = [
        {
          name = "fzf";
          packages = [ pkgs.vimPlugins.telescope-fzf-native-nvim ];
          setup = {
            fzf = {
              fuzzy = true;
            };
          };
        }
      ];

      mappings = {
        buffers = "<leader><leader>";
        diagnostics = "<leader>sd";
        findFiles = "<leader>sf";
        findProjects = "<leader>sp";
        helpTags = "<leader>sh";
        liveGrep = "<leader>sg";
        open = "<leader>st";
        resume = "<leader>sr";
        treesitter = "<leader>ss";
      };

      setupOpts.defaults = {
        path_display = [ "smart" ];

        layout_config.horizontal.prompt_position = "bottom";
        sorting_strategy = "descending";
        color_devicons = true;
      };
    };

    git = {
      neogit.enable = true;
      enable = true;
      gitsigns.setupOpts = {
        signs = {
          add = {
            text = "+";
          };
          change = {
            text = "~";
          };
          delete = {
            text = "_";
          };
          topdelete = {
            text = "‾";
          };
          changedelete = {
            text = "~";
          };
        };
      };
    };
  };
}
