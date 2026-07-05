# modules/nixos/shell — system shell tooling aggregator.
# Sibling files (zsh, direnv, dconf) are auto-imported by the catalog.
# The lib declares the enable options; this file holds cross-cutting
# config only.
{ config, lib, ... }:
{
  config = lib.mkIf config.nixosModules.shell.enable {
    environment.pathsToLink = [ "/share/zsh/" ];
  };
}
