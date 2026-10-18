{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.dolphin") {
    home.packages = with pkgs; [
      (symlinkJoin {
        name = "dolphin-xcb";
        paths = [ kdePackages.dolphin ];
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
  };
}
