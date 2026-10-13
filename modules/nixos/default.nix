{ lib, ... }:

let
  modulesLib = import (lib.my.modules.modules) { inherit lib; };
in
modulesLib.mkHostModules {
  namespace = "nixosModules";
  basePath = ../../modules/nixos;
  entries = [
    {
      name = "desktop";
      sub = [
        "audio"
        "console"
        "fonts"
        "hyprland"
      ];
    }
    {
      name = "gaming";
      optional = true;
      sub = [
        "gamemode"
        "sunshine"
      ];
    }
    {
      name = "networking";
      sub = [
        "firewall"
        "ssh"
        "syncthing"
      ];
    }
    {
      name = "vpn";
      sub = [
        {
          name = "tailscale";
          optional = true;
        }
      ];
    }
    {
      name = "security";
      sub = [
        "gnupg"
        "keyring"
        {
          name = "sandbox";
          optional = true;
        }
        {
          name = "tpm2";
          optional = true;
        }
      ];
    }
    {
      name = "shell";
      sub = [
        "dconf"
        "direnv"
        "zsh"
      ];
    }
    {
      name = "system";
      sub = [
        "nix-ld"
        "packages"
        "user"
      ];
    }
  ];
}
