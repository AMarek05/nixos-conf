# terminal module — aggregates all terminal submodules
{ lib, ... }:

{
  imports = [
    ./man.nix
    ./tmux.nix
    ./ghostty.nix
  ];

  options.hmModules.terminal = {
    enable = lib.mkEnableOption "terminal configuration";
  };
}