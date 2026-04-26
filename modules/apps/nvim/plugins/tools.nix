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
        findProjects = lib.mkForce null;
        findFiles = lib.mkForce null;
        liveGrep = lib.mkForce null;
        buffers = lib.mkForce null;
        helpTags = lib.mkForce null;
        open = lib.mkForce null;
        resume = lib.mkForce null;
        treesitter = lib.mkForce null;
        gitFiles = lib.mkForce null;
        gitCommits = lib.mkForce null;
        gitBufferCommits = lib.mkForce null;
        gitBranches = lib.mkForce null;
        gitStatus = lib.mkForce null;
        gitStash = lib.mkForce null;
        lspDocumentSymbols = lib.mkForce null;
        lspWorkspaceSymbols = lib.mkForce null;
        lspReferences = lib.mkForce null;
        lspImplementations = lib.mkForce null;
        lspDefinitions = lib.mkForce null;
        lspTypeDefinitions = lib.mkForce null;
        diagnostics = lib.mkForce null;
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
