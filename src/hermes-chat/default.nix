{ openssh, writeShellScriptBin }:

writeShellScriptBin "hermes-chat" ''
  set -euo pipefail

  ssh_host="''${HERMES_CHAT_SSH_HOST:-nixos-server}"
  tmux_session="''${HERMES_CHAT_TMUX_SESSION:-hermes-chat}"
  hermes_target="''${HERMES_CHAT_HERMES_TARGET:-hermes@hermes}"
  hermes_cmd="''${HERMES_CHAT_HERMES_CMD:-hermes chat}"

  inner_args=()
  for a in "$@"; do
    inner_args+=("''${a@Q}")
  done

  exec ${openssh}/bin/ssh -t "$ssh_host" \
    tmux new-session -A -s "$tmux_session" \
    "${openssh}/bin/ssh -t $hermes_target $hermes_cmd ''${inner_args[*]}"
''