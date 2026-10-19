{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages.productivity") {
    home.packages = with pkgs; [
      antigravity-hub
      dbeaver-bin
      libreoffice-stable

      remmina

      alacarte
      kdePackages.okular

      intellij-idea
      rust-rover

      thunderbird
    ];
  };
}
