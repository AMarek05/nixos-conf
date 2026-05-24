{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.hmModules.apps.dolphin.enable = lib.mkEnableOption "Enable the dolphin file explorer";

  config = lib.mkIf config.hmModules.apps.dolphin.enable {
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
