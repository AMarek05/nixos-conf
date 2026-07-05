{ lib, ... }:

let
  modulesLib = import ../../lib/modules.nix { inherit lib; };
in
modulesLib.mkHostModules {
  namespace = "nixosModules";
  basePath = ../../modules/nixos;
  entries = [
    {
      name = "desktop";
      kind = "dir";
      sub = [
        { name = "audio"; }
        { name = "console"; }
        { name = "fonts"; }
        { name = "hyprland"; }
      ];
    }
    {
      name = "gaming";
      kind = "dir";
      sub = [
        { name = "gamemode"; }
        { name = "sunshine"; }
      ];
    }
    {
      name = "networking";
      kind = "dir";
      sub = [
        { name = "nm"; }
        { name = "firewall"; }
        { name = "ssh"; }
        { name = "syncthing"; }
        { name = "tools"; }
      ];
    }
    {
      name = "vpn";
      kind = "dir";
      sub = [
        { name = "tailscale"; optional = true; }
      ];
    }
    {
      name = "openclaw";
      kind = "dir";
      optional = true;
    }
    {
      name = "security";
      kind = "dir";
      sub = [
        { name = "gnupg"; }
        { name = "keyring"; }
        { name = "sandbox"; }
        { name = "tpm2"; }
      ];
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
      name = "system";
      kind = "dir";
      sub = [
        { name = "nix-ld"; }
        { name = "packages"; }
        { name = "user"; }
      ];
    }
  ];
}
