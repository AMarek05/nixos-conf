{ pkgs }:
let
  installTerm = pkgs.writeShellScriptBin "install-term" ''
    set -euo pipefail

    if (( $# < 1 )); then
      echo "usage: install-term [--ssh-args ...] <host>" >&2
      exit 2
    fi

    if ! command -v infocmp >/dev/null; then
      echo "install-term: infocmp not on PATH" >&2
      exit 1
    fi

    if ! infocmp -x xterm-ghostty >/dev/null 2>&1; then
      echo "install-term: xterm-ghostty not resolvable locally; check \$TERMINFO or pkgs.ghostty.terminfo" >&2
      exit 1
    fi

    if ! command ssh -o BatchMode=yes -o ConnectTimeout=5 "$@" true 2>/dev/null; then
      echo "install-term: cannot reach $1 via ssh (auth or network); install aborted" >&2
      exit 1
    fi

    if ! infocmp -x xterm-ghostty | command ssh -o BatchMode=yes "$@" -- tic -x -; then
      cat >&2 <<< "install-term: tic failed on remote"
      exit 1
    fi

    echo "install-term: xterm-ghostty installed on $1"
  '';
in
installTerm
