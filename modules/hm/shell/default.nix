# shell module — aggregates all shell submodules and provides HM options
{ lib, ... }:

{
  imports = [
    ./links.nix
    ./scripts.nix
    ./zsh.nix
    ./starship.nix
  ];

  options.hmModules.shell = {
    enable = lib.mkEnableOption "shell configuration";
  };
}