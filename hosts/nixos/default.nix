{
  pkgs,
  lib,
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

  nix.package = pkgs.lix;

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

    Host amarek
      HostName 212.127.78.174
      Port 2222

      User root

    Host hermes
      HostName 192.168.100.12
      Port 22
      User hermes
      ProxyJump nixos-server
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
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  systemd.services."systemd-userdb".enable = false;
  systemd.services."systemd-homed".enable = false;

  systemd.sockets."systemd-userdb".enable = false;

  time.timeZone = lib.mkDefault "Europe/Warsaw";

  system.stateVersion = "25.05";
}
