{ pkgs, ... }:
{
  programs.nvf.settings.vim = {

    binds.whichKey.enable = true;
    utility.sleuth.enable = true;
    comments.comment-nvim.enable = true;

    visuals.nvim-web-devicons.enable = true;

    autopairs.nvim-autopairs.enable = true;

    languages = {
      enableFormat = true;
      enableLSP = true;
      enableTreesitter = true;

      nix.enable = true;
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
