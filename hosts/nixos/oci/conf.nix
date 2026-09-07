{ pkgs, ... }: {
  nix.package = pkgs.lix;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
      "https://cache.amarek.pl/nixos-cache"
      "https://mic92.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "nixos-cache:Jp03HL/iNrPtKzxlNt1BoGlYVXv8NWpN/yoX1cd8ppc="
      "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
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
}
