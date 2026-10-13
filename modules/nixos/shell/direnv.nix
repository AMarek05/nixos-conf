# modules/nixos/shell/direnv.nix — direnv with nix-direnv integration.
{ config, lib, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "shell.direnv") {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
