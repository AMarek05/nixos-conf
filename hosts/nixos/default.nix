{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../../modules/nixos/default.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/openclaw.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  sops.secrets."gh-token-nix" = {
    owner = "root";
    key = "gh-token";
  };

  sops.templates."nix-access-token" = {
    owner = "root";
    content = ''
      access-tokens = github.com=${config.sops.placeholder."gh-token-nix"}
    '';
  };

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

  nix.extraOptions = ''
    !include ${config.sops.templates."nix-access-token".path}
  '';

  programs.nix-index-database = {
    enable = true;
    comma.enable = true;
  };

  programs.nix-index.enableZshIntegration = lib.mkForce false;
  programs.nix-index.enableBashIntegration = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    gnupg

    nix-visualize
    nix-tree

    tpm2-tools
    tpm2-tss
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  systemd.services."systemd-userdb".enable = false;
  systemd.services."systemd-homed".enable = false;

  systemd.sockets."systemd-userdb".enable = false;

  time.timeZone = lib.mkDefault "Europe/Warsaw";

  system.stateVersion = "25.05";
}
