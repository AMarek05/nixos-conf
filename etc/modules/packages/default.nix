# packages/default.nix
{ lib }:
{
  imports = [
    ./system.nix
    ./gaming.nix
  ];

  options.modules.packages = {
    enable = lib.mkEnableOption "packages";
    system = {
      enable = lib.mkEnableOption "packages/system";
    };
    gaming = {
      enable = lib.mkEnableOption "packages/gaming";
    };
  };
}
