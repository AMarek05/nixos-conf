{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hmModules.user.util;
in
{
  imports = [ ./rust.nix ];

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      custom.mmx-cli
      custom.sqldeveloper

      file
      zip
      unzip
      unrar-free
      p7zip
      zstd
      pv

      brightnessctl
      playerctl
      acpi
      wineWow64Packages.stableFull
      winetricks

      tldr

      nh
      nvd
      cachix

      emacs
      pandoc

      wl-clipboard
      bat
      imv
      fzf
      fd
      ripgrep

      wget2
      nauty

      fastfetch

      gnumake
      cmake
      parallel
      shellcheck
      python3
      gcc
      nodejs
      zig
      R

      pkgs.custom.kanban-tail
      pkgs.custom.hermes-chat
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
