{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  programs.nvf = {
    enable = false;
  };
}
