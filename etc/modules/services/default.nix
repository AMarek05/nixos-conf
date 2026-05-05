# services/default.nix
{ lib }:
{
  imports = [
    ./audio.nix
    ./syncthing.nix
    ./flatpak.nix
    ./sshd.nix
    ./gnome-keyring.nix
  ];

  options.modules.services = {
    enable = lib.mkEnableOption "services";
    audio = {
      enable = lib.mkEnableOption "services/audio";
    };
    syncthing = {
      enable = lib.mkEnableOption "services/syncthing";
    };
    flatpak = {
      enable = lib.mkEnableOption "services/flatpak";
    };
    sshd = {
      enable = lib.mkEnableOption "services/sshd";
    };
    gnome-keyring = {
      enable = lib.mkEnableOption "services/gnome-keyring";
    };
  };
}
