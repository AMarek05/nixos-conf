# OpenClaw Tool: git-agent
# Description: Agentic git tool with push support (non-main branches only), clone, fetch, pull, commit, checkout, branch operations.
# Supports both HTTPS and SSH GitHub integration.

{
  pkgs,
  cfg,
  config,
  ...
}:

let
  script = builtins.readFile ./Bash/git-agent.sh;
in

{
  name = "git-agent";
  permissions = "0750";

  description = "Agentic git tool: clone, fetch, pull, push (non-main branches), commit, checkout, create-branch, status, diff, log, branch. Read+write GitHub integration.";

  usage = "git-agent <clone|fetch|pull|push|commit|checkout|create-branch|status|diff|log|branch> [args...]";

  arguments = [
    {
      name = "operation";
      desc = "The git operation to perform";
      default = "required";
    }
    {
      name = "target";
      desc = "Contextual argument depending on operation";
      default = "current directory (.)";
    }
    {
      name = "--dir";
      desc = "Specific target directory for clone operation";
      default = "workspace/git/<repo-name>";
    }
    {
      name = "--all|-a";
      desc = "Stage all tracked files (commit) or show all branches (branch)";
      default = "false";
    }
    {
      name = "--rebase";
      desc = "Perform a rebase instead of merge during pull";
      default = "false";
    }
    {
      name = "--short|-s";
      desc = "Show output in short format (status)";
      default = "false";
    }
    {
      name = "--cached";
      desc = "View staged changes (diff)";
      default = "false";
    }
    {
      name = "-n <num>";
      desc = "Number of commits to return (log)";
      default = "10";
    }
    {
      name = "-b";
      desc = "Create a new branch (checkout)";
      default = "false";
    }
    {
      name = "--verbose|-v";
      desc = "Show verbose output (branch)";
      default = "false";
    }
    {
      name = "--force|-f";
      desc = "Force push (use with caution)";
      default = "false";
    }
  ];

  examples = [
    "git-agent clone git@github.com:user/repo.git --dir my-repo"
    "git-agent pull"
    "git-agent push origin my-feature-branch"
    "git-agent create-branch my-feature-branch"
    "git-agent commit \"fix: resolve null pointer exception\" --all"
  ];

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

    check_push_safe() {
      local branch="$1"
      [[ "$branch" =~ ^(main|master)$ ]] && fail "Push to '$branch' is not allowed. Use a feature branch." 1
      true
    }

    # Universally apply SSH key for ALL git commands (clone, fetch, pull, push)
    SSH_KEY_PATH=$(get_ssh_key)

    if [[ -n "$SSH_KEY_PATH" ]]; then
      export GIT_SSH_COMMAND="ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"
    fi

    exec ${script} "$@"
  '';
}
