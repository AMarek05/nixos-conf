{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default

    ./nvim/binds.nix
    ./nvim/opts.nix
    ./nvim/plugins.nix
  ];

  programs.nvf = {
    enable = true;

    settings.vim = {
      globals.maplocalleader = " ";
    };
  };
}
