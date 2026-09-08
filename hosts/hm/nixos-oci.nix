{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
  ];

  hmModules = {
    apps = {
      stylix.enable = false;
      dolphin.enable = false;

      packages.enable = false;
    };

    caelestia.enable = false;
    hyprland.enable = false;

    terminal.ghostty.enable = false;
  };

  programs.git.signing.key = lib.mkForce "/home/adam/.ssh/git";

  programs.zsh.shellAliases.read-sops = lib.mkForce "SOPS_AGE_KEY=$(${lib.getExe pkgs.ssh-to-age} -private-key -i /var/lib/sops-nix/age_key) ${lib.getExe pkgs.sops}";
}