# shell module — aggregates all shell submodules and provides HM options
{ lib, ... }:
{
  options.modules.shell = {
    enable = lib.mkEnableOption "shell";
  };

  config = lib.mkIf config.modules.shell.enable {
    imports = [
      ./zsh.nix
      ./scripts.nix
    ];
  };
}