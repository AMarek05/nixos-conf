# shell module — aggregates all shell submodules and provides HM options
{ lib, ... }:

{
  imports = [
    ./scripts.nix
    ./zsh.nix
    ./starship.nix
  ];

  options.modules.shell = {
    enable = lib.mkEnableOption "shell configuration";
  };
}