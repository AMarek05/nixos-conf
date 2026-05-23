# terminal module — aggregates all terminal submodules
{ lib, ... }:

{
  imports = [
    ./man.nix
    ./tmux.nix
    ./ghostty.nix
  ];

  options.modules.terminal = {
    enable = lib.mkEnableOption "terminal configuration";
  };
}