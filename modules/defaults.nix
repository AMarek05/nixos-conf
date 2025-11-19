{ lib, ... }:
{
  imports = [
    ./git.nix
    ./nvim.nix
    ./shell.nix
  ];

  modules.git.enable = lib.mkDefault true;
  # modules.nvim.enable = lib.mkDefault true;
  # modules.shell.enable = lib.mkDefault true;
}
