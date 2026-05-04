# shell module — aggregates all shell submodules and provides HM options
{ ... }:
{
  imports = [
    ./scripts.nix
    ./zsh.nix
    ./starship.nix
  ];
}

