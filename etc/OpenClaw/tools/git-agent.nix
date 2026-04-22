# OpenClaw Tool: git-agent
# Description: Agentic git tool with push support (non-main branches only), clone, fetch, pull, commit, checkout, branch operations.
# Supports both HTTPS and SSH GitHub integration.

{
  pkgs,
  cfg,
  config,
  ...
}:

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
      name = "-n<NUM>";
      desc = "Number of commits to return (log)";
      default = "10";
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
    "git-agent clone git@github.com:user/repo.git --dir=my-repo"
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

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"

    # Standardized JSON error response handler
    fail() {
      jq -n --arg error "$1" --argjson code "''${2:-1}" \
        '{success: false, exit_code: $code, error: $error}'
      exit "''${2:-1}"
    }

    resolve_path() {
      local p="$1"

      p="$(realpath -m "$p")"

      if ! [[ "$p" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "Outside workspace: $p" >&2
        return 2
      fi
      if [[ "$p" == "$CONFIG_DIR"* ]]; then
        echo ".openclaw blocked" >&2
        return 2
      fi
      echo "$p"
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

    OP="''${1:-}"
    [[ -z $OP ]] && fail "Usage: git-agent <clone|fetch|pull|push|commit|checkout|create-branch|status|diff|log|branch> [args]" 1

    case $OP in
      clone)
        REPO=""
        TARGET_DIR=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == --dir=* ]]; then
            TARGET_DIR="''${arg#*=}"
          elif [[ ! "$arg" =~ ^- && -z "$REPO" ]]; then
            REPO="$arg"
          fi
        done

        [[ -z "$REPO" ]] && fail "clone needs a URL" 1

        if [[ -n "$TARGET_DIR" ]]; then
          TARGET_DIR="$(resolve_path "$TARGET_DIR")" || fail "Invalid target directory" 2
        else
          TARGET_DIR="$(basename "$REPO" .git)"
          TARGET_DIR="$WORKSPACE/git/$TARGET_DIR"
        fi
        mkdir -p "$(dirname "$TARGET_DIR")"

        TOKEN=$(get_gh_token)
        EXIT_CODE=0
        RESULT=""

        if [[ "$REPO" =~ ^https://github\.com/ ]]; then
          if [[ -n "$TOKEN" ]]; then
            local repo_path="''${REPO#https://github.com/}"
            RESULT=$(git clone --recursive "https://x-access-token:$TOKEN@github.com/$repo_path" "$TARGET_DIR" 2>&1) || EXIT_CODE=$?
          else
            RESULT=$(git clone --recursive "$REPO" "$TARGET_DIR" 2>&1) || EXIT_CODE=$?
          fi
        else
          # SSH and fallback handles naturally via exported GIT_SSH_COMMAND
          RESULT=$(git clone --recursive "$REPO" "$TARGET_DIR" 2>&1) || EXIT_CODE=$?
        fi

        jq -n \
          --arg op "clone" \
          --arg repo "$REPO" \
          --arg path "$TARGET_DIR" \
          --argjson code "$EXIT_CODE" \
          --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, repo: $repo, path: $path, exit_code: $code, output: $output}'
        ;;

      fetch)
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git fetch --all 2>&1) || EXIT_CODE=$?

        jq -n --arg op "fetch" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
          --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
        ;;

      pull)
        WDIR="."
        REBASE=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--rebase" ]]; then
            REBASE="--rebase"
          elif [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git pull $REBASE 2>&1) || EXIT_CODE=$?

        jq -n --arg op "pull" --arg dir "$WDIR" \
          --argjson rebase "$([[ "$REBASE" == "--rebase" ]] && echo true || echo false)" \
          --argjson code "$EXIT_CODE" --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, dir: $dir, rebase: $rebase, exit_code: $code, output: $output}'
        ;;

      push)
        REMOTE=""
        BRANCH=""
        FORCE=""
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
            FORCE="--force"
          elif [[ ! "$arg" =~ ^- ]]; then
            if [[ -z "$REMOTE" ]]; then
              REMOTE="$arg"
            elif [[ -z "$BRANCH" ]]; then
              BRANCH="$arg"
            else
              [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
            fi
          fi
        done

        [[ -z "$REMOTE" ]] && REMOTE="origin"
        
        # If user runs `push feature-branch`, swap variables to `push origin feature-branch`
        if [[ -z "$BRANCH" && "$REMOTE" != "origin" ]]; then
          BRANCH="$REMOTE"
          REMOTE="origin"
        fi

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        [[ -z "$BRANCH" ]] && BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        check_push_safe "$BRANCH"

        TOKEN=$(get_gh_token)
        EXIT_CODE=0
        RESULT=""

        if [[ -n "$TOKEN" ]] && [[ "$(git remote get-url "$REMOTE" 2>/dev/null)" =~ ^https://github.com/ ]]; then
          local remote_url=$(git remote get-url "$REMOTE")
          local repo_path="''${remote_url#https://github.com/}"
          git remote set-url "$REMOTE" "https://x-access-token:$TOKEN@github.com/$repo_path"
          RESULT=$(git push $FORCE "$REMOTE" "$BRANCH" 2>&1) || EXIT_CODE=$?
          git remote set-url "$REMOTE" "$remote_url"
        else
          RESULT=$(git push $FORCE "$REMOTE" "$BRANCH" 2>&1) || EXIT_CODE=$?
        fi

        jq -n --arg op "push" --arg remote "$REMOTE" --arg branch "$BRANCH" \
          --argjson forced "$([[ -n "$FORCE" ]] && echo true || echo false)" \
          --argjson code "$EXIT_CODE" --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, remote: $remote, branch: $branch, forced: $forced, exit_code: $code, output: $output}'
        ;;

      commit)
        MSG=""
        STAGED=""
        WDIR="."

        for arg in "''${@:2}"; do
          if [[ "$arg" == "--all" || "$arg" == "-a" ]]; then
            STAGED="--all"
          elif [[ -z "$MSG" && ! "$arg" =~ ^- ]]; then
            MSG="$arg"
          elif [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        [[ -z "$MSG" ]] && fail "commit needs a message. Usage: git-agent commit <message> [--all|-a] [dir]" 1

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        if [[ "$STAGED" == "--all" ]]; then
          git add --all 2>/dev/null || true
        fi

        EXIT_CODE=0
        RESULT=$(git commit -m "$MSG" 2>&1) || EXIT_CODE=$?

        if [[ $EXIT_CODE -eq 0 ]]; then
          HASH=$(git log -1 --format=%H)
          jq -n --arg op "commit" --arg hash "$HASH" --arg msg "$MSG" \
            --argjson code "$EXIT_CODE" --arg output "$RESULT" \
            '{success: true, operation: $op, hash: $hash, message: $msg, exit_code: $code, output: $output}'
        else
          jq -n --arg op "commit" --arg msg "$MSG" --argjson code "$EXIT_CODE" --arg error "$RESULT" \
            '{success: false, operation: $op, message: $msg, exit_code: $code, error: $error}'
        fi
        ;;

      checkout)
        BRANCH=""
        CREATE=false
        WDIR="."

        for arg in "''${@:2}"; do
          if [[ "$arg" == "-b" ]]; then
            CREATE=true
          elif [[ "$arg" =~ ^- ]]; then
            : # ignore other flags
          elif [[ -z "$BRANCH" ]]; then
            BRANCH="$arg"
          else
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        [[ -z "$BRANCH" ]] && fail "checkout needs a branch name. Usage: git-agent checkout <branch> [-b] [dir]" 1

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        if [[ "$CREATE" == true ]]; then
          RESULT=$(git checkout -b "$BRANCH" 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(git checkout "$BRANCH" 2>&1) || EXIT_CODE=$?
        fi

        jq -n --arg op "checkout" --arg branch "$BRANCH" --argjson created "$CREATE" \
          --argjson code "$EXIT_CODE" --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, branch: $branch, created: $created, exit_code: $code, output: $output}'
        ;;

      create-branch)
        BRANCH=""
        BASE="main"
        WDIR="."

        for arg in "''${@:2}"; do
          if [[ "$arg" == "-b" ]] || [[ "$arg" =~ ^- ]]; then
            : # ignore flags
          elif [[ -z "$BRANCH" ]]; then
            BRANCH="$arg"
          else
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        [[ -z "$BRANCH" ]] && fail "create-branch needs a name. Usage: git-agent create-branch <branch> [base-branch] [dir]" 1

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git checkout -b "$BRANCH" 2>&1) || EXIT_CODE=$?

        jq -n --arg op "create-branch" --arg branch "$BRANCH" \
          --argjson code "$EXIT_CODE" --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, branch: $branch, exit_code: $code, output: $output}'
        ;;

      status)
        WDIR="."
        SHORT=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--short" || "$arg" == "-s" ]]; then
            SHORT="--short"
          elif [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git status $SHORT 2>&1) || EXIT_CODE=$?

        jq -n --arg op "status" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
          --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
        ;;

      diff)
        OPT=""
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--cached" ]]; then
            OPT="--cached"
          elif [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git diff $OPT 2>&1) || EXIT_CODE=$?

        jq -n --arg op "diff" --arg dir "$WDIR" \
          --argjson cached "$([[ "$OPT" == "--cached" ]] && echo true || echo false)" \
          --argjson code "$EXIT_CODE" --arg output "$RESULT" \
          '{success: ($code == 0), operation: $op, dir: $dir, cached: $cached, exit_code: $code, output: $output}'
        ;;

      log)
        NUM=10
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ "$arg" =~ ^-n[0-9]+$ ]]; then 
            NUM="''${arg#-n}"
          elif [[ ! "$arg" =~ ^- ]]; then 
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        LOG_TMP=$(mktemp)
        ERR_TMP=$(mktemp)

        git log -n "$NUM" --format="%H%x00%an%x00%ai%x00%s" > "$LOG_TMP" 2> "$ERR_TMP" || EXIT_CODE=$?

        if [[ $EXIT_CODE -eq 0 ]]; then
          ENTRIES_JSON=$(jq -Rs -c '[split("\n")[] | select(length > 0) | split("\u0000") | {hash: .[0], author: .[1], date: .[2], message: .[3]}]' "$LOG_TMP")
          jq -n --arg op "log" --arg dir "$WDIR" --argjson count "$NUM" \
            --argjson entries "$ENTRIES_JSON" --argjson code "$EXIT_CODE" \
            '{success: true, operation: $op, dir: $dir, count: $count, exit_code: $code, entries: $entries}'
        else
          jq -n --arg op "log" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
            --arg error "$(cat "$ERR_TMP")" \
            '{success: false, operation: $op, dir: $dir, exit_code: $code, error: $error}'
        fi
        rm -f "$LOG_TMP" "$ERR_TMP"
        ;;

      branch)
        WDIR="."
        ALLB=""
        VERBOSE=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "-a" || "$arg" == "--all" ]]; then
            ALLB="-a"
          elif [[ "$arg" == "-v" || "$arg" == "--verbose" ]]; then
            VERBOSE="-v"
          elif [[ ! "$arg" =~ ^- ]]; then
            [[ "$arg" != "." || "$WDIR" == "." ]] && WDIR="$arg"
          fi
        done

        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"

        EXIT_CODE=0
        RESULT=$(git branch $ALLB $VERBOSE 2>&1) || EXIT_CODE=$?

        jq -n --arg op "branch" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
          --arg branches "$RESULT" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, branches: $branches}'
        ;;

      *)
        fail "Unknown operation: $OP. Use clone, fetch, pull, push, commit, checkout, create-branch, status, diff, log, or branch" 1
        ;;
    esac
  '';
}
