{ lib, ... }:
{
  imports = [
    ./modules/audio.nix
    ./modules/console.nix
    ./modules/fonts.nix
    ./modules/gamemode.nix
    ./modules/networking.nix
    ./modules/packages.nix
    ./modules/printing.nix
    ./modules/security.nix
    ./modules/shell.nix
    ./modules/user.nix
    ./modules/nix-ld.nix
    ./modules/flatpak.nix
    ./modules/vpn.nix
  ];

  modules = {
    user.enable = lib.mkDefault true;
    shell.enable = lib.mkDefault true;
    audio.enable = lib.mkDefault true;
    console.enable = lib.mkDefault true;
    fonts.enable = lib.mkDefault true;
    gamemode.enable = lib.mkDefault true;
    networking.enable = lib.mkDefault true;
    packages.enable = lib.mkDefault true;
    printing.enable = lib.mkDefault true;
    security.enable = lib.mkDefault true;
    nix-ld.enable = lib.mkDefault true;
    flatpak.enable = lib.mkDefault true;
    vpn.enable = lib.mkDefault true;
  };
}
