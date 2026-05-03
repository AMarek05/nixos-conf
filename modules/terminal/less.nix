# less module — colorized manpages via NixOS programs.less.termcap
# translates the classic LESS_TERMCAP_* ANSI sequences into Nix-native termcap
{ lib, ... }:
{
  options.modules.terminal.less = {
    enable = lib.mkEnableOption "less-termcap";
  };

  config = lib.mkIf config.modules.terminal.less.enable {
    programs.less.termcap = {
      xterm-256color = {
        mb = "1;31";   # begin blinking — bold red
        md = "1;31";   # begin bold — bold red
        me = "0";      # end all formatting
        se = "0";      # end standout
        so = "1;33;44"; # begin standout — bold yellow fg, blue bg (search hits)
        ue = "0";      # end underline
        us = "4;1;32"; # begin underline — underline + bold + green
        mr = "7";      # reverse-video
        mh = "2";      # dim
        ZN = "74";     # subscript on (uncommon)
        ZV = "75";     # subscript off
        ZO = "73";     # superscript on (uncommon)
        ZW = "75";     # superscript off
      };
    };

    programs.less.enable = true;
  };
}