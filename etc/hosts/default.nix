{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../modules

    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
    ];

    trusted-users = [
      "root"
      "adam"
    ];

    max-jobs = "auto";
    cores = 0;

    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;

  time.timeZone = lib.mkDefault "Europe/Warsaw";

  system.stateVersion = "25.05";
}
