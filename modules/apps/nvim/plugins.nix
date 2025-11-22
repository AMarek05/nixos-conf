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

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix = {
        enable = true;
        format.type = "nixfmt";
        lsp.server = "nixd";
      };
    };

    dashboard.alpha.enable = true;

    lsp = {
      enable = true;

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

    ui = {
      noice.enable = true;
      noice.setupOpts.routes = [
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
      enable = true;
      neogit.enable = true;
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

    luaConfigRC.lsp-diagnostics = ''
    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.diagnostic.config({
      signs = true,             -- Show the icons in the left column
      virtual_text = true,      -- Show text after the code line
      underline = true,         -- Underline the error in the code
      update_in_insert = false, -- Don't scream at me while I'm typing
      severity_sort = true,     -- Put errors above warnings
    })
  '';
  };
}
