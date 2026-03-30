{ pkgs, ... }:
let
  compress = pkgs.writeShellApplication {
    name = "compress";
    runtimeInputs = with pkgs; [
      gnutar
      pv
      zstd
      gawk
      coreutils
    ];
    text = ''
      # Compress directories with zstd and show a progress bar
      # Output archives are saved in the current directory

      if [ $# -lt 1 ]; then
          echo "Usage: $0 <dir1> [dir2 dir3 ...]"
          exit 1
      fi

      ZSTD_LEVEL=19
      OUTDIR="$(pwd)"

      for dir in "$@"; do
          if [ ! -d "$dir" ]; then
              echo "ERR: Skipping '$dir': not a directory"
              continue
          fi

          base_name="$(basename "$dir")"
          output="''${OUTDIR}/''${base_name}.tar.zst"

          size_bytes=$(du -sb "$dir" | awk '{print $1}')
          size_human=$(du -sh "$dir" | awk '{print $1}')

          echo "LOG: Compressing '$dir' ($size_human) → '$output'"

          tar -cf - -C "$(dirname "$dir")" "$base_name" \
              | pv -s "$size_bytes" -pterb \
              | zstd -"''${ZSTD_LEVEL}" -T0 -o "$output"

          echo "EXIT: Done: $output"
          echo
      done
    '';
  };

  conf = pkgs.writeShellApplication {
    name = "conf";
    runtimeInputs = with pkgs; [
      git
      nh
      coreutils
    ];
    text = ''
      REPO="/home/adam/sys"
      ETC="/home/adam/sys/etc/"
      FLAKE="/home/adam/sys/flake.nix"

      cd "$REPO"

      git add "$ETC" "$FLAKE"
      echo "Proceeding to rebuild:"

      nh os switch

      git commit -m "$(date +'%H:%M - %d %B %Y')"
    '';
  };

  confw = pkgs.writeShellApplication {
    name = "confw";
    runtimeInputs = with pkgs; [
      git
      nh
      coreutils
    ];
    text = ''
      REPO="/home/adam/sys"
      ETC="/home/adam/sys/etc"
      FLAKE="/home/adam/sys/flake.nix"

      cd "$REPO"

      nvim "''${ETC}/configuration.nix"

      git add "$ETC" "$FLAKE"
      echo "Proceeding to rebuild:"

      nh os switch

      git commit -m "$(date +'%H:%M - %d %B %Y')"
    '';
  };

  home = pkgs.writeShellApplication {
    name = "home";
    runtimeInputs = with pkgs; [
      git
      nh
      coreutils
    ];
    text = ''
      REPO="/home/adam/sys"
      MODULES="''${REPO}/modules"
      STORE="''${REPO}/store"
      HOSTS="''${REPO}/hosts"
      FLAKE="''${REPO}/flake.nix"

      cd "$REPO"

      git add "$HOSTS" "$MODULES" "$STORE" "$FLAKE"

      nh home switch

      git commit -m "$(date +'%H:%M - %d %B %Y')"
    '';
  };

in
{
  # Add the scripts to your user's environment
  home.packages = [
    compress
    conf
    confw
    home
  ];
}
