# terminal module — aggregates all terminal submodules
{ lib, ... }:
{
  options.modules.terminal = {
    enable = lib.mkEnableOption "terminal";
  };

  imports = [
    ./less.nix
    ./tmux.nix
    ./ghostty.nix
    ./starship.nix
  ];
}