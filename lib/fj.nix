# lib/fj.nix
{ pkgs, config }:
let
  fj-wrapper = pkgs.writeShellScriptBin "fj" ''
    set -euo pipefail

    FJ_AUTH_PATH = ${config.sops.secrets."fj-auth".path}

    if [[ -f "$FJ_AUTH_PATH" ]]; then
      # Read the raw token from the decrypted SOPS file
      # and export it so the fj binary automatically picks it up
      export FORGEJO_TOKEN="$(cat "$FJ_AUTH_PATH")"
    fi

    exec ${pkgs.forgejo-cli}/bin/fj --host "https://git.amarek.pl" "$@"
  '';
in
fj-wrapper
