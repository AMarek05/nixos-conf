{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.console = {
    enable = lib.mkEnableOption "console (fonts, keymap)";
  };

  config = lib.mkIf config.nixosModules.console.enable {
    console = {
      enable = true;
      packages = with pkgs; [ terminus_font ];
      font = "ter-v16n";
      keyMap = "us";
    };
  };
}
