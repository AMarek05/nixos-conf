{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (symlinkJoin {
      name = "dolphin-xcb";
      paths = [ kdePackages.dolphin ]; # Use pkgs.dolphin if on older KDE 5
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/dolphin \
          --set QT_QPA_PLATFORM xcb
      '';
    })
    kdePackages.dolphin-plugins
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
  ];
}
