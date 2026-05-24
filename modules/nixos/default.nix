{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostNixosModules {
  basePath = ../../modules/nixos;
  entries = [
    { name = "audio";      kind = "file"; }
    { name = "console";    kind = "file"; }
    { name = "fonts";      kind = "file"; }
    { name = "gamemode";   kind = "file"; }
    { name = "hyprland";   kind = "file"; }
    { name = "networking"; kind = "file"; }
    { name = "nix-ld";     kind = "file"; }
    { name = "openclaw";   kind = "dir";  optional = true; }
    { name = "packages";   kind = "file"; }
    { name = "sandbox";    kind = "file"; optional = true; }
    { name = "security";   kind = "file"; }
    { name = "shell";      kind = "file"; }
    { name = "user";       kind = "file"; }
    { name = "vpn";        kind = "file"; }
  ];
}