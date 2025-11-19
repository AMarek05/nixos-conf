{ lib, ... }:
{
  imports = [
    ./git.nix
    ./nvim.nix
    ./shell.nix
    ./util.nix
  ];

  modules.git.enable = lib.mkDefault true;
  modules.util.enable = lib.mkDefault true;
  # modules.nvim.enable = lib.mkDefault true;
  # modules.shell.enable = lib.mkDefault true;
}
