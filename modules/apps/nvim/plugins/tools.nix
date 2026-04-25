{ pkgs, inputs, ... }:
{
  programs.nvf.settings.vim = {
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
        layout_config.horizontal.prompt_position = "bottom";
        sorting_strategy = "descending";
        color_devicons = true;
      };
    };

    lazy.plugins."overseer.nvim" = {
      package = pkgs.vimPlugins.overseer-nvim;
      setupModule = "overseer";

      setupOpts = {
        strategy = "terminal";
        templates = [ "builtin" ];
        task_list = {
          direction = "bottom";
          min_height = 10;
          max_height = 20;
          default_detail = 1;
        };
      };
    };

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
