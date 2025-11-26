{
  pkgs,
  inputs,
  ...
}:
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

    mini = {
      surround.enable = true;
    };

    binds.whichKey.enable = true;
    comments.comment-nvim.enable = true;
    visuals.nvim-web-devicons.enable = true;
    autopairs.nvim-autopairs.enable = true;
    minimap.codewindow.enable = true;
    treesitter.context = {
      enable = true;
      setupOpts = {
        maxLines = 5;
        multiline_threshold = 1;
        trim_scope = "outer";
        mode = "cursor";
      };
    };

    autocomplete.blink-cmp = {
      enable = true;
      mappings.next = null;
      setupOpts = {
        cmdline = {
          completion = {
            list = {
              selection = {
                preselect = true;
                auto_insert = true;
              };
            };
            menu = {
              auto_show = false;
            };
            ghost_text = {
              enabled = false;
            };
          };
          keymap = {
            preset = "default";
            "<CR>" = [
              "fallback"
            ];
          };
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
      python.enable = true;
      rust.enable = true;
      zig.enable = true;
      zig.lsp.package = [ "zls" ];
      go.enable = true;

      nix = {
        enable = true;
        format.type = "nixfmt";
        lsp.server = "nixd";
        lsp.options = {
          nixpkgs = {
            expr = "import (builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).inputs.nixpkgs {}";
          };
          options = {
            nixos = {
              expr = "(builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).nixosConfigurations.nixos.options";
            };

            home-manager = {
              expr = "(builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).homeConfigurations.\"adam@nixos\".options";
            };
          };
        };
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

      setupOpts = {
        path_display = [ "filename_first" ];
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
    luaConfigRC.telescope_fix = inputs.nvf.lib.nvim.dag.entryAfter [ "telescope" ] ''
      require("telescope").setup({
        pickers = {
          find_files = {
            path_display = { "filename_first" }
          },
          live_grep = {
            path_display = { "filename_first" }
          },
          oldfiles = {
            path_display = { "filename_first" }
          }
        }
      })
      local status, builtin = pcall(require, "telescope.builtin")

      if status then
        local original_find_files = builtin.find_files

        -- Overwrite the function to inject our setting every time it runs
        builtin.find_files = function(opts)
          opts = opts or {}
          -- This acts as a hard override
          opts.path_display = { "filename_first" }
          original_find_files(opts)
        end
      end
    '';
  };
}
