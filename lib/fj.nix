# lib/fj.nix
{ pkgs, config }:
let
  fj-wrapper = pkgs.writeShellScriptBin "fj" ''
    set -euo pipefail

    FJ_AUTH_PATH="${config.sops.secrets."fj-auth".path}"
    STATE_FILE="$HOME/.cache/fj-token-synced"

    if [[ -f "$FJ_AUTH_PATH" ]]; then
      if [[ ! -f "$STATE_FILE" ]] || [[ "$FJ_AUTH_PATH" -nt "$STATE_FILE" ]]; then
        TOKEN="$(cat "$FJ_AUTH_PATH")"

        ${pkgs.forgejo-cli}/bin/fj --host "https://git.amarek.pl" auth add-key Claw "$TOKEN" >/dev/null 2>&1 || true

        # Touch the state file to update its timestamp
        mkdir -p "$(dirname "$STATE_FILE")"
        touch "$STATE_FILE"
      fi
    fi

    exec ${pkgs.forgejo-cli}/bin/fj --host "https://git.amarek.pl" "$@"
  '';
in
fj-wrapper
