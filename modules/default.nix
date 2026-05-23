{ lib, ... }:

let
  modulesLib = import ../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostHmModules {
  basePath = ../modules;
  entries = [
    # files
    { name = "env";    kind = "file"; optional = false; }
    { name = "git";    kind = "file"; optional = false; }
    { name = "links";  kind = "file"; optional = false; }
    { name = "util";   kind = "file"; optional = false; }
    # dirs with nested options
    {
      name = "apps";
      kind = "dir";
      optional = false;
      sub = [
        { name = "stylix"; optional = false; }
        { name = "nvf";    optional = false; }
      ];
    }
    { name = "caelestia"; kind = "dir"; optional = false; }
    {
      name = "hyprland";
      kind = "dir";
      optional = false;
      sub = [
        { name = "caelestia"; optional = false; }
      ];
    }
    {
      name = "shell";
      kind = "dir";
      optional = false;
      sub = [
        { name = "zsh";     optional = false; }
        { name = "starship"; optional = false; }
      ];
    }
    {
      name = "terminal";
      kind = "dir";
      optional = false;
      sub = [
        { name = "ghostty"; optional = false; }
        { name = "man";     optional = false; }
        { name = "tmux";    optional = false; }
      ];
    }
  ];
}