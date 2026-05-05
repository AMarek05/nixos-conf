# nix/settings.nix — nix daemon settings, substituters, experimental features
{ lib, config }:
let
  cfg = config.modules.nix.settings;
in
{
  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [
        "https://cache.nixos.org/"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      max-jobs = "auto";
      cores = 0;
    };

    nix.settings.trusted-users = [
      "root"
      "adam"
    ];

    nixpkgs.config.allowUnfree = true;

    # enable flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
