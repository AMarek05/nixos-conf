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
      pv

      brightnessctl
      playerctl
      acpi
      jmtpfs
      wine64

      nh
      nvd
      cachix

      wl-clipboard
      bat
      fzf
      fd
      ripgrep

      wget2
      nauty
      koboldcpp

      fastfetch

      gnumake
      parallel
      shellcheck
      python3
      gcc
      nodejs
      zig
    ];

    programs.java = {
      enable = true;
      package = pkgs.openjdk25;
    };

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
