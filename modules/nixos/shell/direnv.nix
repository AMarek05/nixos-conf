# modules/nixos/shell/direnv.nix — direnv with nix-direnv integration.
{
  config,
  lib,
  ...
}:
{
  options.nixosModules.shell.direnv.enable = lib.mkEnableOption "direnv with nix-direnv";

  config = lib.mkIf (
    config.nixosModules.shell.enable &&
    config.nixosModules.shell.direnv.enable
  ) {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
