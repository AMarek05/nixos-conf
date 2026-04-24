{
  utility = {
    sleuth.enable = true;
    surround.enable = true;
    undotree.enable = true;

    oil-nvim = {
      enable = true;
      gitStatus.enable = true;
      setupOpts = {
        float = {
          border = "rounded";

          max_width = 0.7;
          max_height = 0.5;

          padding = 2;
        };

        preview = {
          border = "rounded";
        };

        keymaps = {
          "q" = "actions.close";
          "w" = ":w<CR>";
          "x" = ":wq<CR>";
        };
      };
    };

    outline.aerial-nvim = {
      enable = true;
      setupOpts = {
        show_guides = true;
        default_direction = "float";
      };
    };
  };

  mini = {
    surround.enable = true;
  };

  lazy.plugins."flash.nvim" = {
    package = pkgs.vimPlugins.flash-nvim;
    setupModule = "flash";

    lazy = false;

    setupOpts = {
      modes = {
        char = {
          highlight = {
            backdrop = false;
          };

          charActions = ''
            function(motion)
              return {
                [";"] = "next", -- keep standard vim behavior for next
                [","] = "prev", -- keep standard vim behavior for previous
              }
            end,
          '';
          search = {
            highlight = {
              backdrop = false;
            };
          };
        };
      };
    };
  };
}
