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
  };
}
