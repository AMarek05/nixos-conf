{ lib, ... }:

let
  modulesLib = import ../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostHmModules {
  basePath = ../modules;
  entries = [
    # files
    { name = "env";    kind = "file"; }
    { name = "git";    kind = "file"; }
    { name = "links";  kind = "file"; }
    { name = "util";   kind = "file"; }
    # dirs with nested options
    {
      name = "apps";
      kind = "dir";
      sub = [
        { name = "stylix"; }
        { name = "nvf";    }
      ];
    }
    { name = "caelestia"; kind = "dir"; }
    {
      name = "hyprland";
      kind = "dir";
      sub = [
        { name = "caelestia"; }
      ];
    }
    {
      name = "shell";
      kind = "dir";
      sub = [
        { name = "zsh";       }
        { name = "starship"; disabledByDefault = true; }
      ];
    }
    {
      name = "terminal";
      kind = "dir";
      sub = [
        { name = "ghostty"; }
        { name = "man";     }
        { name = "tmux";    }
      ];
    }
  ];
}