# less module — colorized manpages via LESS_TERMCAP_* session variables
# idiomatic NixOS/HM way: set them as environment session vars
{ lib, ... }:
{
  options.modules.terminal.less = {
    enable = lib.mkEnableOption "less-termcap";
  };

  config = lib.mkIf config.modules.terminal.less.enable {
    home.sessionVariables = {
      MANPAGER = "less";

      # Begin blinking text mode — bold red
      LESS_TERMCAP_mb = "\\e[1;31m";
      # Begin bold text mode — bold red
      LESS_TERMCAP_md = "\\e[1;31m";
      # End all special formatting
      LESS_TERMCAP_me = "\\e[0m";
      # End standout mode
      LESS_TERMCAP_se = "\\e[0m";
      # Begin standout mode — bold yellow fg, blue bg (search hits)
      LESS_TERMCAP_so = "\\e[1;33;44m";
      # End underline mode
      LESS_TERMCAP_ue = "\\e[0m";
      # Begin underline mode — underline + bold + green
      LESS_TERMCAP_us = "\\e[4;1;32m";
      # Begin reverse-video mode
      LESS_TERMCAP_mr = "\\e[7m";
      # Begin dim/half-bright mode
      LESS_TERMCAP_mh = "\\e[2m";
      # Subscript on (uncommon)
      LESS_TERMCAP_ZN = "\\e[74m";
      # Subscript off
      LESS_TERMCAP_ZV = "\\e[75m";
      # Superscript on (uncommon)
      LESS_TERMCAP_ZO = "\\e[73m";
      # Superscript off
      LESS_TERMCAP_ZW = "\\e[75m";
    };
  };
}