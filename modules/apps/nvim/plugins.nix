{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    utility.sleuth.enable = true;
    comments.comment-nvim.enable = true;
    git = {
      enable = true;
      gitsigns.setupOpts = {
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
      neogit.enable = true;
    };
  };
}
