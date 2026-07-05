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

  config = lib.mkIf (config.hmModules.apps.packages.enable && config.hmModules.apps.packages.browsers.enable) {
    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };

    programs.zen-browser.enable = true;
  };
}
