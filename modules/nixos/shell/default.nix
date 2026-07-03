# modules/nixos/shell — system shell tooling aggregator.
# Each sibling is gated by both the parent (nixosModules.shell.enable)
# and its own sub-enable, so disabling the parent cascades to all
# siblings while individual subs remain independently toggleable.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixosModules.shell;
in
{
  imports = [
    ./zsh.nix
    ./direnv.nix
    ./dconf.nix
  ];

  options.nixosModules.shell.enable = lib.mkEnableOption "system shell configuration (zsh, direnv, dconf)";

  # Cross-cutting shell config: pathsToLink is shared by all subs.
  config = lib.mkIf cfg.enable {
    environment.pathsToLink = [ "/share/zsh/" ];
  };
}
