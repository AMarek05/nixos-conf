# nix/default.nix
{ lib }:
{
  imports = [
    ./settings.nix
    ./ld.nix
  ];

  options.modules.nix = {
    enable = lib.mkEnableOption "nix";
    settings = {
      enable = lib.mkEnableOption "nix/settings";
    };
    ld = {
      enable = lib.mkEnableOption "nix/ld";
    };
  };
}
