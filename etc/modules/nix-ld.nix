{ lib, ... }:
{
  options.modules.nix-ld = {
    enable = lib.mkEnableOption "nix-ld runtime loader";
  };

  config = lib.mkIf config.modules.nix-ld.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glib
      libwebp
      SDL2
      SDL2_image
      SDL2_ttf
      SDL2_mixer
      libpng
      libjpeg
      freetype
      fontconfig
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
      libglvnd
      alsa-lib
      pulseaudio
      glew
      glfw
      ffmpeg
      dbus
      gtk3
      expat
      libxft
    ];
  };
}
