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
      "nixos-cache:NYH7cc9sD0f2oKbN42Oo7Bw7TkDyfvjrS2Isa5CY4GM="
      "mic92.cachix.org-1:a7mH/Y6n6pS611g2a4Y+7GjC8f6F7hY3K3mBq7M="
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

  programs.ssh.extraConfig = ''
    Host nixos-server
      HostName nixos-server
      User adam
      ProxyJump admin

      ForwardAgent yes

    Host proxmox
      HostName proxmox
      User root
      ProxyJump admin

      ForwardAgent yes

    Host admin
      HostName admin
      User root

      ForwardAgent yes

    Host hermes
      HostName 192.168.100.12
      Port 22
      User hermes
      ProxyJump nixos-server

    Host pangolin
      HostName amarek.pl
      Port 2222
      User ubuntu
  '';

  programs.nix-index-database = {
    enable = true;
    comma.enable = true;
  };

  programs.nix-index.enableZshIntegration = lib.mkForce false;
  programs.nix-index.enableBashIntegration = lib.mkForce false;

  environment.systemPackages = with pkgs; [
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
