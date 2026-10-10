{ openssh, writeShellScriptBin }:

writeShellScriptBin "kanban-tail" ''
  set -euo pipefail

  if (( $# < 1 )) || [[ ''${1-} == -* && ''${1-} != "--" ]]; then
    echo "usage: kanban-tail [<board>] <task-id> [-- tail-flags...]" >&2
    echo "  <board>    optional kanban board slug (default: 'default')" >&2
    echo "  <task-id>  kanban task id, with or without 't_' prefix" >&2
    echo "  --         pass remaining args through to tail (default: -F)" >&2
    echo "" >&2
    echo "env: KANBAN_TAIL_SSH_HOST  (default: hermes)" >&2
    echo "     KANBAN_TAIL_LOG_ROOT  (default: /var/lib/hermes/.hermes/kanban)" >&2
    exit 2
  fi

  # Collect positional operands before '--' or options
  pos=()
  while (( $# > 0 )); do
    case "$1" in
      --)
        shift
        break
        ;;
      -*)
        break
        ;;
      *)
        pos+=("$1")
        shift
        ;;
    esac
  done

  case ''${#pos[@]} in
    1)
      board="default"
      raw="''${pos[0]}"
      ;;
    2)
      board="''${pos[0]}"
      raw="''${pos[1]}"
      ;;
    *)
      echo "kanban-tail: expected [<board>] <task-id>, got ''${#pos[@]} arguments" >&2
      exit 2
      ;;
  esac

  id="''${raw#t_}"
  if ! [[ "$id" =~ ^[a-f0-9]+$ ]]; then
    echo "kanban-tail: '$raw' is not a valid task id (expected hex, with or without 't_' prefix)" >&2
    exit 1
  fi

  ssh_host="''${KANBAN_TAIL_SSH_HOST:-hermes}"
  log_root="''${KANBAN_TAIL_LOG_ROOT:-/var/lib/hermes/.hermes/kanban}"

  if [[ "$board" == "default" ]]; then
    log_file="$log_root/logs/t_$id.log"
  else
    log_file="$log_root/boards/$board/logs/t_$id.log"
  fi

  if [[ $# -eq 0 ]]; then
    set -- -F
  fi

  exec ${openssh}/bin/ssh -o BatchMode=yes "$ssh_host" tail "$@" "$log_file"
''
