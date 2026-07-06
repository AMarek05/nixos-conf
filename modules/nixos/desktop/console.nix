{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.nixosModules.desktop.console.enable {
    console = {
      enable = true;
      packages = with pkgs; [ terminus_font ];
      font = "ter-v16n";
      keyMap = "us";
    };
  };
}
