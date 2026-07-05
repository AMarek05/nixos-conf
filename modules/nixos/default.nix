{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostModules {
  namespace = "nixosModules";
  basePath = ../../modules/nixos;
  entries = [
    {
      name = "audio";
      kind = "file";
    }
    {
      name = "console";
      kind = "file";
    }
    {
      name = "fonts";
      kind = "file";
    }
    {
      name = "gamemode";
      kind = "file";
    }
    {
      name = "hyprland";
      kind = "file";
    }
    {
      name = "networking";
      kind = "dir";
      sub = [
        { name = "nm"; }
        { name = "firewall"; }
        { name = "syncthing"; }
        { name = "ssh"; }
        { name = "tools"; }
      ];
    }
    {
      name = "nix-ld";
      kind = "file";
    }
    {
      name = "openclaw";
      kind = "dir";
      optional = true;
    }
    {
      name = "packages";
      kind = "file";
    }
    {
      name = "sandbox";
      kind = "file";
      optional = true;
    }
    {
      name = "security";
      kind = "file";
    }
    {
      name = "shell";
      kind = "dir";
      sub = [
        { name = "zsh"; }
        { name = "direnv"; }
        { name = "dconf"; }
      ];
    }
    {
      name = "user";
      kind = "file";
    }
    {
      name = "vpn";
      kind = "file";
    }
    {
      name = "tailscale";
      kind = "file";
      optional = true;
    }
    {
      name = "sunshine";
      kind = "file";
      optional = true;
    }
  ];
}
