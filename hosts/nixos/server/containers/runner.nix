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
    owner = "root";
    mode = "0400";
  };

  nix.settings = {
    sandbox = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    narinfo-cache-negative-ttl = 0;
    trusted-users = [
      "root"
      "runner"
      "@wheel"
    ];
  };

  services.forgejo-runner = {
    instances."native" = {
      enable = true;
      url = "https://git.amarek.pl";

      settings.server.connections.default.uuid = "5012e7fb-5114-417e-ad1e-e8994a08047a";
      secrets.server.connections.default.token_url = config.sops.secrets."runner-token".path;

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
        attic-client

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
}
