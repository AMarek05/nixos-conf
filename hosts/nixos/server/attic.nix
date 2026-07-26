{
  pkgs,
  inputs,
  config,
  myLib,
  ...
}:
let
  git-wrapper = myLib.git-wrapper { inherit pkgs config; };
in
{
  imports = [
    inputs.attic.nixosModules.atticd
  ];

  environment.systemPackages = with pkgs; [ attic-client ];

  sops.secrets."attic_token" = {
    sopsFile = inputs.self + "/secrets/serv.yaml";
    owner = "atticd";
    group = "atticd";
  };

  sops.templates."attic_rsa_token" = {
    owner = "atticd";
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."attic_token"}
    '';
  };

  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
  };

  users.groups.atticd = { };

  sops.secrets."claw-ssh-key" = {
    sopsFile = inputs.self + "/secrets/openclaw.yaml";
    owner = "root";
  };

  sops.secrets."gh-token" = {
    sopsFile = inputs.self + "/secrets/openclaw.yaml";
    owner = "root";
  };

  sops.secrets."attic_key" = {
    sopsFile = inputs.self + "/secrets/serv.yaml";
    owner = "atticd";
  };

  systemd.services.update-attic = {
    description = "Update flake.lock, build hosts, and push to git/attic";

    requires = [ "atticd.service" ];
    after = [ "atticd.service" ];

    # Ensure all necessary binaries are in the path.
    # Replace `pkgs.git` with your wrapped git package if it's passed via pkgs.
    path =
      with pkgs;
      [
        lix
        attic-client
        coreutils
        openssh
        nh
      ]
      ++ [ git-wrapper ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    script = ''
      set -euo pipefail

      WORKDIR=$(mktemp -d -p /var/tmp)

      # Ensure cleanup happens even if the script fails midway
      trap 'rm -rf "$WORKDIR"' EXIT

      export HOME="$WORKDIR"
      cd "$WORKDIR"

      attic login local-attic http://127.0.0.1:8888 $(cat ${config.sops.secrets."attic_key".path})

      echo "Cloning repository..."
      git clone --depth=1 git@amarek.pl:amarek/nixos-conf.git repo

      cd repo
      git switch -c pulls/flake-update

      echo "Updating flake.lock..."
      export NIX_CONFIG="access-tokens = github.com=$(cat ${config.sops.secrets."gh-token".path})"
      nix flake update

      TARGETS=(
        ".#nixosConfigurations.nixos.config.system.build.toplevel"
        ".#nixosConfigurations.nixos-laptop.config.system.build.toplevel"
        ".#nixosConfigurations.nixos-server.config.system.build.toplevel"
        ".#homeConfigurations.\"adam@nixos\".activationPackage"
        ".#homeConfigurations.\"adam@nixos-laptop\".activationPackage"
        ".#homeConfigurations.\"adam@nixos-server\".activationPackage"
      )

      for TARGET in "''${TARGETS[@]}"; do
        echo "Building $TARGET..."
        nix build -L "$TARGET"

        echo "Pushing closure to attic..."
        attic push local-attic:nixos-cache ./result

        echo "Cleaning up local symlink..."
        rm -f ./result
      done

      if ! git diff --quiet flake.lock; then
        echo "Changes detected in flake.lock, committing..."
        git add flake.lock
        git commit -m "chore(flake): update lockfile and cache closures"
        git push --force origin pulls/flake-update
      else
        echo "No updates available for flake.lock."
      fi

      echo "Starting the cleanup..."
      nh clean all --keep 3 --optimise
    '';
  };

  systemd.timers.update-attic = {
    description = "Timer to run flake-updater every 5 days";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Runs every 5th day of the month starting on the 1st, at 3AM
      OnCalendar = "*-*-1/5 03:00:00";
      Persistent = true;
    };
  };

  services.atticd = {
    enable = true;

    environmentFile = config.sops.templates."attic_rsa_token".path;

    user = "atticd";
    group = "atticd";

    settings = {
      listen = "[::]:8888";

      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 256 * 1024; # 256 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 1 * 1024 * 1024; # 1 MiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 4 * 1024 * 1024; # 4 MiB
      };
    };
  };
}
