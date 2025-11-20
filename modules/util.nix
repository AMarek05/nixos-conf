{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.util;
in
{
  options.modules.util = {
    enable = lib.mkEnableOption "util";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      unzip
      unrar-free
      p7zip
      nh
      fastfetch
      zstd
      wl-clipboard
    ];
  };
}
