# shell module — aggregates all shell submodules and provides HM options
{ lib, ... }:
{
  options.modules.shell = {
    enable = lib.mkEnableOption "shell";
  };

  imports = [
    ./zsh.nix
    ./scripts.nix
  ];
}