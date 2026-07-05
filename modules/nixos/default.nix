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
        { name = "sunshine"; createOption = false; }
      ];
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
      name = "network";
      kind = "dir";
      sub = [
        { name = "vpn"; }
        { name = "tailscale"; optional = true; }
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
      kind = "dir";
      sub = [
        { name = "gnupg"; }
        { name = "keyring"; }
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
      name = "user";
      kind = "file";
    }
  ];
}
