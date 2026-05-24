{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostHmModules {
  basePath = ../../modules/hm;
  entries = [
    # dirs with nested options
    {
      name = "user";
      kind = "dir";
    }
    {
      name = "apps";
      kind = "dir";
      sub = [
        { name = "stylix"; }
        { name = "nvf"; }
        { name = "dolphin"; }
      ];
    }
    {
      name = "caelestia";
      kind = "dir";
    }
    {
      name = "hyprland";
      kind = "dir";
    }
    {
      name = "shell";
      kind = "dir";
      sub = [
        { name = "links"; }
        {
          name = "scripts";
        }
        {
          name = "starship";
          optional = true;
        }
        {
          name = "zsh";
        }
      ];
    }
    {
      name = "terminal";
      kind = "dir";
      sub = [
        { name = "ghostty"; }
        { name = "man"; }
        { name = "tmux"; }
      ];
    }
  ];
}
