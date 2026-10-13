{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.packages.browsers") {
    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };

    programs.zen-browser.enable = true;
  };
}
