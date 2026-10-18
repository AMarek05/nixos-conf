{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "desktop.console") {
    console = {
      enable = true;
      packages = with pkgs; [ terminus_font ];
      font = "ter-v16n";
      keyMap = "us";
    };
  };
}
