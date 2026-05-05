# nix/ld.nix — programs.nix-ld and library set for dynamic linking
{ pkgs, lib, config }:
let
  cfg = config.modules.nix.ld;
in
{
  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      # --- The Basics ---
      stdenv.cc.cc.lib
      zlib
      glib

      # --- The Crash Fixes (Image & Graphics) ---
      libwebp
      SDL2
      SDL2_image
      SDL2_ttf
      SDL2_mixer
      libpng
      libjpeg
      freetype
      fontconfig

      # --- X11 / Windowing ---
      libX11
      libXext
      libXrender
      libXcursor
      libXrandr
      libXinerama
      libXi
      libXScrnSaver
      libxcb
      libxcb-cursor

      # --- OpenGL & Audio ---
      libglvnd
      alsa-lib
      pulseaudio

      glew
      glfw

      # --- Video / Extras ---
      ffmpeg
      dbus
      gtk3

      expat
      libxft
    ];
  };
}
