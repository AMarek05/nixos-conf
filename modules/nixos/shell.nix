{ config, lib, ... }:
let
  cfg = config.nixosModules.shell;
in
{
  options.nixosModules.shell = {
    enable = lib.mkEnableOption "system shell configuration (zsh, direnv, dconf)";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    programs.dconf.enable = true;

    environment.pathsToLink = [ "/share/zsh/" ];
  };
}
