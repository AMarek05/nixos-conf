{ config, lib, pkgs, ... }:
let
  cfg = config.modules.util;
in
{
  options.modules.util = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable commandline utilities";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      unzip
      unrar
      p7zip
      nh
      fastfetch
    ];
  };
}
