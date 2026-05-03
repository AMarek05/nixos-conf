# terminal module — aggregates all terminal submodules
{ lib, ... }:
{
  options.modules.terminal = {
    enable = lib.mkEnableOption "terminal";
  };

  config = lib.mkIf config.modules.terminal.enable {
    imports = [
      ./less.nix
      ./tmux.nix
      ./ghostty.nix
      ./starship.nix
    ];
  };
}