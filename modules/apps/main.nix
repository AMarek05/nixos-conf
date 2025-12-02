{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.modules.apps = {
    enable = lib.mkEnableOption "apps";
  };

  config = lib.mkIf config.modules.apps.enable {
    home.packages = with pkgs; [
      heroic
      keepassxc

      rustlings

      yazi
    ];

    gtk = {
      enable = lib.mkForce true;
      colorScheme = "dark";
    };

    programs.firefox.enable = true;
    programs.zen-browser.enable = true;
  };
}
