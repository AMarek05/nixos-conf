{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."runner-token" = {
    sopsFile = inputs.self + "/secrets/serv.yaml";
    owner = "runner";
    mode = "0400";
  };

  nix.settings = {
    sandbox = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;

    instances."native" = {
      enable = true;
      name = "nixos-nspawn-runner";
      url = "https://git.amarek.pl";

      tokenFile = config.sops.secrets."runner-token".path;

      # The :host suffix bypasses Docker/Podman
      labels = [
        "nixos:host"
      ];

      # Explicitly provide the path dependencies for your jobs
      hostPackages = with pkgs; [
        coreutils

        curl
        wget

        bash
        gitMinimal
        nh

        gawk
        gnused

        nodejs
        nix
        cargo
        gcc
        clang
      ];
    };
  };

  systemd.services."gitea-runner-native" = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "runner";
      Group = lib.mkForce "runner";
      BindReadOnlyPaths = [ "/run/secrets/runner-token" ];

      TimeoutStartSec = "10s";
    };
  };
}
