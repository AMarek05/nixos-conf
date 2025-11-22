{
  inputs,
  pkgs,
  lib,
  ...
}:

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
      theme = {
        transparent = lib.mkForce true;
        name = lib.mkForce "tokyonight";
        style = "night";
      };
      globals.maplocalleader = " ";
    };
  };
}
