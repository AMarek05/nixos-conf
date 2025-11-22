{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  programs.nvf = {
    enable = false;

    settings = {
      vim.opt.number = true;
    };
  };
}
