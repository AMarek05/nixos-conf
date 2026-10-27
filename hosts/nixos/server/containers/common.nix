{ config, pkgs, ... }:
let
  name = config.networking.hostName;
in
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://hermes-agent.cachix.org"
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
      "https://cache.amarek.pl/nixos-cache"
      "https://mic92.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "nixos-cache:Jp03HL/iNrPtKzxlNt1BoGlYVXv8NWpN/yoX1cd8ppc="
      "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
    ];
  };

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "5s";
    };
  };

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users = {
    users."${name}" = {
      group = name;
      isSystemUser = true;

      shell = pkgs.bash;
      home = "/var/lib/${name}";

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSrgBs2fy3oRYtbmbXNEkJ8JpqS2L8U/RPqVEojiOAu6OWzT8EXaMHwHhxMjXIXp2fzCaXrbZCV9is9rckuLuQ= id-laptop"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMVue17Ck5epd5LBWWWd9Es+XN+IFtdkMxy2NHkFbtghXH+1lujMQxTjv3ZUD0R2pt8jfycdNqNmiH4QnjYpSgI= id-nixos"
      ];
    };
  };
}
