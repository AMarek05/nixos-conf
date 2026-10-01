{ openssh, writeShellScriptBin }:

writeShellScriptBin "kanban-tail" ''
  set -euo pipefail

  if (( $# < 1 )); then
    echo "usage: kanban-tail <task-id> [-- tail-flags...]" >&2
    echo "  <task-id>  kanban task id, with or without 't_' prefix (e.g. 26b2d7cf or t_26b2d7cf)" >&2
    echo "  --         pass remaining args through to tail (default: -F)" >&2
    echo "" >&2
    echo "env: KANBAN_TAIL_SSH_HOST (default: hermes)" >&2
    echo "     KANBAN_TAIL_LOG_DIR  (default: /var/lib/hermes/.hermes/kanban/logs)" >&2
    exit 2
  fi

  raw="$1"
  shift

  id="''${raw#t_}"
  if ! [[ "$id" =~ ^[a-f0-9]+$ ]]; then
    echo "kanban-tail: '$raw' is not a valid task id (expected hex, with or without 't_' prefix)" >&2
    exit 1
  fi

  ssh_host="''${KANBAN_TAIL_SSH_HOST:-hermes}"
  log_dir="''${KANBAN_TAIL_LOG_DIR:-/var/lib/hermes/.hermes/kanban/logs}"
  log_file="$log_dir/t_$id.log"

  if [[ $# -eq 0 ]]; then
    set -- -F
  fi

  exec ${openssh}/bin/ssh -o BatchMode=yes "$ssh_host" tail "$@" "$log_file"
''
