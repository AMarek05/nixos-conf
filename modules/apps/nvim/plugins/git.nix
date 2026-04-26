{ pkgs, lib, ... }:
{
  programs.nvf.settings.vim = {
    git = {
      enable = true;
      neogit.enable = true;
      git-conflict = {
        mappings = {
          ours = lib.mkForce null;
          theirs = lib.mkForce null;
          both = lib.mkForce null;
          none = lib.mkForce null;
          prevConflict = lib.mkForce null;
          nextConflict = lib.mkForce null;
        };
      };
      gitsigns = {
        mappings = {
          stageHunk = lib.mkForce null;
          undoStageHunk = lib.mkForce null;
          resetHunk = lib.mkForce null;
          stageBuffer = lib.mkForce null;
          resetBuffer = lib.mkForce null;
          previewHunk = lib.mkForce null;
          blameLine = lib.mkForce null;
          toggleBlame = lib.mkForce null;
          diffThis = lib.mkForce null;
          diffProject = lib.mkForce null;
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
