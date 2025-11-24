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
      zstd

      nh
      nvd
      cachix

      wl-clipboard
      bat

      vlc

      fastfetch
    ];

    programs.btop = {
      enable = true;
      settings = {
        color_theme = lib.mkForce "tokyo-night";
        theme_background = lib.mkForce false;
        vim_keys = true;
      };
    };
  };
}
