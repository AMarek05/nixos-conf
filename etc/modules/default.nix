{ lib, ... }:
{
  imports = [
    ./audio.nix

    ./packages.nix
    ./nix-ld.nix
    ./sandbox.nix

    ./user.nix
    ./shell.nix

    ./console.nix
    ./fonts.nix

    ./security.nix

    ./networking.nix
    ./vpn.nix
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
    security.enable = lib.mkDefault true;
    nix-ld.enable = lib.mkDefault true;
    flatpak.enable = lib.mkDefault true;
    vpn.enable = lib.mkDefault true;
  };
}
