# i18n/console.nix — TTY console font and keymap
{ pkgs, lib, config }:
let
  cfg = config.modules.i18n.console;
in
{
  config = lib.mkIf cfg.enable {
    console = {
      enable = true;
      packages = with pkgs; [ terminus_font ];

      font = "ter-v16n";

      keyMap = "us";
    };
  };
}
