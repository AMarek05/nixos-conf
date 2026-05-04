# terminal module — aggregates all terminal submodules
{ ... }:
{
  imports = [
    ./man.nix
    ./tmux.nix
    ./ghostty.nix
  ];
}
