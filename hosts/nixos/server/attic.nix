{
  pkgs,
  inputs,
  config,
  myLib,
  ...
}:
let
  git-wrapper = myLib.git-wrapper { inherit pkgs config; };
  fj-wrapper = myLib.fj-wrapper { inherit pkgs config; };

  servSecrets = inputs.self + "/secrets/serv.yaml";
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
    sopsFile = servSecrets;
    owner = "atticd";
  };

  sops.secrets."fj-auth" = {
    sopsFile = servSecrets;
    owner = "root";
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
      ++ [
        git-wrapper
        fj-wrapper
      ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    script = ''
      set -euo pipefail

      WORKDIR=$(mktemp -d -p /var/tmp)

      trap 'rm -rf "$WORKDIR"' EXIT

      export HOME="$WORKDIR"
      cd "$WORKDIR"

      attic login local-attic http://127.0.0.1:8888 $(cat ${config.sops.secrets."attic_key".path})

      echo "Cloning repository..."
      git clone git@amarek.pl:amarek/nixos-conf.git repo

      cd repo
      git switch -c pulls/flake-update

      echo "Updating flake.lock..."
      nix flake update

      if git diff --quiet flake.lock; then
        echo "No updates available for flake.lock. Skipping."
        exit 0
      fi

      echo "Changes detected in flake.lock, committing..."
      git add flake.lock
      git commit -m "chore(flake): update lockfile and cache closures"

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

      git push --force origin pulls/flake-update

      echo "Opening Pull Request..."
      fj pr create \
        "chore(flake): update lockfile" \
        --body "Automated flake update and closure cache generation from \`update-attic.service\`." \
        --head pulls/flake-update \
        --base main \
        --cwd "$WORKDIR/repo" \
        --repo amarek/nixos-conf \
        || echo "PR likely already exists. Skipping PR creation."

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

  services.postgresql = {
    enable = true;

    ensureDatabases = [ "atticd" ];
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
  };

  services.atticd = {
    enable = true;

    environmentFile = config.sops.templates."attic_rsa_token".path;

    user = "atticd";
    group = "atticd";

    settings = {
      listen = "[::]:8888";

      database.url = "postgresql://atticd@%2Frun%2Fpostgresql/atticd";

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

  systemd.services.atticd = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
