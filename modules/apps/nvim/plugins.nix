{ pkgs, ... }:
{
  programs.nvf.settings.vim.plugins = {
    Comment = {
      package = pkgs.vimPlugins.comment-nvim;
      setupModule = "Comment";
    };
    vim-sleuth = {
      package = pkgs.vimPlugins.vim-sleuth;
    };
    gitsigns = {
      package = pkgs.vimPlugins.gitsigns-nvim;
      setupModule = "gitsigns";
      setupOpts = {
        signs = {
          add = {
            text = "+";
          };
          change = {
            text = "~";
          };
          delete = {
            text = "~";
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
