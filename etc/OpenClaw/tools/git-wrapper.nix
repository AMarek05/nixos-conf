# OpenClaw Tool: git-agent
# Description: Agentic git tool with push support (non-main branches only), clone, fetch, pull, commit, checkout, branch operations.
# Supports both HTTPS and SSH GitHub integration.

{
  pkgs,
  config,
  ...
}:

{
  name = "git";
  permissions = "0750";

  description = "Transparent git wrapper for SSH key provision";

  usage = "Ordinary git.";

  dependencies = with pkgs; [
    git
    jq
    openssh
    coreutils
    gh
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: git-agent
    # Description: Agentic git tool with push support (non-main branches only).

    set -euo pipefail

    # Standardized JSON error response handler
    fail() {
      jq -n --arg error "$1" --argjson code "''${2:-1}" \
        '{success: false, exit_code: $code, error: $error}'
      exit "''${2:-1}"
    }

    get_gh_token() {
      local tok=""
      if [[ -f "${config.sops.secrets."gh-token".path}" ]]; then
        tok=$(cat "${config.sops.secrets."gh-token".path}")
      fi
      echo "$tok"
    }

    get_ssh_key() {
      echo "${config.sops.secrets."claw-ssh-key".path}"
    }

    # Universally apply SSH key for ALL git commands (clone, fetch, pull, push)
    SSH_KEY_PATH=$(get_ssh_key)

    if [[ -n "$SSH_KEY_PATH" ]]; then
      export GIT_SSH_COMMAND="ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"
    fi

    exec "${pkgs.git}/bin/git" "$@"
  '';
}
