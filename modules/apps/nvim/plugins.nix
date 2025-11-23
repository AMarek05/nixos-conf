{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    extraPlugins = {
      nvim-lastplace = {
        package = pkgs.vimPlugins.nvim-lastplace;
        setup = "require('nvim-lastplace').setup {}";
      };
    };

    statusline.lualine = {
      enable = true;
      setupOpts = {
        options.theme = "tokyonight";
      };
    };

    utility = {
      sleuth.enable = true;
      surround.enable = true;
      undotree.enable = false;
      motion = {
        leap.enable = true;
        flash-nvim.enable = true;
      };
    };

    binds.whichKey.enable = true;
    comments.comment-nvim.enable = true;
    visuals.nvim-web-devicons.enable = true;
    autopairs.nvim-autopairs.enable = true;
    minimap.codewindow.enable = true;
    treesitter.context.enable = true;

    autocomplete.blink-cmp = {
      enable = true;
      setupOpts = {
        cmdLine.keymap = {
          preset = "none";
          "<Tab>" = [
            "show"
            "select_next"
            "fallback"
          ];
          "<S-Tab>" = [
            "select_prev"
            "fallback"
          ];
          "<CR>" = [
            "accept"
          ];
        };
        keymap = {
          preset = "default";
          "<C-n>" = [
            "snippet_forward"
            "fallback"
          ];
          "<C-p>" = [
            "snippet_backward"
            "fallback"
          ];
        };
      };
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      clang.enable = true;

      nix = {
        enable = true;
        format.type = "nixfmt";
      };
    };

    dashboard.alpha.enable = true;

    lsp = {
      enable = true;

      formatOnSave = true;
      inlayHints.enable = true;

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
      borders.enable = true;
      illuminate.enable = true;

      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };
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
        # path_display = [ "smart" ];

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

    luaConfigRC.telescope-path-display = ''
      -- Telescope is already loaded by NVF, so we can just update the setup
      require("telescope").setup({
        defaults = {
          path_display = { "filename_first" }
        }
      })
    '';
  };
}
