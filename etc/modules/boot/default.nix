# boot/default.nix
{ lib }:
{
  imports = [
    ./loader.nix
    ./kernel.nix
  ];

  options.modules.boot = {
    enable = lib.mkEnableOption "boot";
    loader = {
      enable = lib.mkEnableOption "boot/loader";
    };
    kernel = {
      enable = lib.mkEnableOption "boot/kernel";
    };
  };
}
