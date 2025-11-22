{ pkgs, ... }:
{
  programs.nvf.settings.vim = {

    binds.whichKey.enable = true;
    utility.sleuth.enable = true;
    comments.comment-nvim.enable = true;

    visuals.nvim-web-devicons.enable = true;

    telescope.enable = true;

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
