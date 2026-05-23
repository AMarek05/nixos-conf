{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostNixosModules {
  entries = [
    { name = "audio";       kind = "file"; optional = false; }
    { name = "console";     kind = "file"; optional = false; }
    { name = "fonts";       kind = "file"; optional = false; }
    { name = "gamemode";    kind = "file"; optional = false; }
    { name = "networking";  kind = "file"; optional = false; }
    { name = "nix-ld";      kind = "file"; optional = false; }
    { name = "packages";    kind = "file"; optional = false; }
    { name = "sandbox";     kind = "file"; optional = true;  }
    { name = "security";    kind = "file"; optional = false; }
    { name = "shell";       kind = "file"; optional = false; }
    { name = "user";        kind = "file"; optional = false; }
    { name = "vpn";         kind = "file"; optional = false; }
  ];
}