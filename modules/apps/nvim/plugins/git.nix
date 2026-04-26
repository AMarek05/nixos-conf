{ pkgs, lib, ... }:
{
  programs.nvf.settings.vim = {
    git = {
      enable = true;
      neogit.enable = true;
      gitsigns = {
        mappings = {
          toggleBlame = lib.mkForce null;
          toggleDeleted = lib.mkForce null;
        };
      };
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

    lazy.plugins."diffview.nvim" = {
      package = pkgs.vimPlugins.diffview-nvim;
      setupModule = "diffview";
      setupOpts = {};
    };
  };
}
