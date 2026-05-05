# i18n/default.nix
{ lib }:
{
  imports = [
    ./locale.nix
    ./console.nix
    ./fonts.nix
  ];

  options.modules.i18n = {
    enable = lib.mkEnableOption "i18n";
    locale = {
      enable = lib.mkEnableOption "i18n/locale";
    };
    console = {
      enable = lib.mkEnableOption "i18n/console";
    };
    fonts = {
      enable = lib.mkEnableOption "i18n/fonts";
    };
  };
}
