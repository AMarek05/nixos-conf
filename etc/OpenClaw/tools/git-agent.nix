# OpenClaw Tool: git-agent
# Description: Agentic git tool: clone, fetch, pull, commit (local only, no push). Read-only GitHub integration.

{
  pkgs,
  cfg,
  ...
}:

{
  name = "git-agent";
  permissions = "0750";

  description = "Agentic git tool: clone, fetch, pull, commit (local only, no push). Supports both HTTPS and SSH read-only GitHub integration.";

  usage = "git-agent <clone|fetch|pull|commit|status|diff|log|branch> [args...]";

  arguments = [
    {
      name = "operation";
      desc = "The git operation to perform (clone, fetch, pull, commit, status, diff, log, branch)";
      default = "required";
    }
    {
      name = "target";
      desc = "Contextual argument depending on operation: Repo URL (clone), commit message (commit), or target directory (others)";
      default = "current directory (.)";
    }
    {
      name = "--dir";
      desc = "Specific target directory for the clone operation. Creates it if needed.";
      default = "workspace/git/<repo-name>";
    }
    {
      name = "--all|-a";
      desc = "Stage all tracked files (for commit) or show all local and remote branches (for branch)";
      default = "false";
    }
    {
      name = "--rebase";
      desc = "Perform a rebase instead of a merge during a pull";
      default = "false";
    }
    {
      name = "--short|-s";
      desc = "Show output in short format (for status)";
      default = "false";
    }
    {
      name = "--cached";
      desc = "View staged changes instead of unstaged changes (for diff)";
      default = "false";
    }
    {
      name = "-n<NUM>";
      desc = "Number of commits to return (for log)";
      default = "10";
    }
    {
      name = "--verbose|-v";
      desc = "Show verbose output (for branch)";
      default = "false";
    }
  ];

  examples = [
    "git-agent clone git@github.com:torvalds/linux.git --dir=linux-source"
    "git-agent commit \"fix: resolve null pointer exception\" --all"
    "git-agent log -n5 src/api"
    "git-agent status --short"
    "git-agent diff --cached"
  ];

  dependencies = with pkgs; [
    git
    jq
    openssh
    coreutils
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: git-agent
    # Description: Agentic git tool: clone, fetch, pull, commit (local only, no push). Read-only GitHub integration.
    # Status: REVIEWED

    set -euo pipefail

    # Standardized JSON error response handler
    fail() {
      jq -n --arg error "$1" --argjson code "''${2:-1}" \
        '{success: false, exit_code: $code, error: $error}'
      exit "''${2:-1}"
    }

    OP="''${1:-}"
    [[ -z $OP ]] && fail "Usage: git-agent <clone|fetch|pull|commit|status|diff|log|branch> [args]" 1

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"

    resolve_path() {
      local p="$1"
      [[ "$p" != /* ]] && p="$WORKSPACE/$p"
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

    check_push() {
      for arg in "$@"; do
        [[ "$arg" =~ ^push$|^--push$ ]] && fail "Push is not allowed" 1
      done
      true
    }

    case $OP in
      clone)
        REPO="''${2:-}"
        [[ -z "$REPO" ]] && fail "clone needs a URL" 1
        check_push "$REPO"
        
        TARGET_DIR=""
        if [[ "''${3:-}" == --dir=* ]]; then
          TARGET_DIR="''${3#*=}"
          TARGET_DIR="$(resolve_path "$TARGET_DIR")" || fail "Invalid target directory" 2
        else
          TARGET_DIR="$(basename "$REPO" .git)"
          TARGET_DIR="$WORKSPACE/git/$TARGET_DIR"
        fi
        mkdir -p "$(dirname "$TARGET_DIR")"
        
        EXIT_CODE=0
        if [[ "$REPO" =~ github\.com ]]; then
          RESULT=$(git clone --recursive "$REPO" "$TARGET_DIR" 2>&1) || EXIT_CODE=$?
        else
          fail "Only GitHub URLs are permitted." 1
        fi
        
        jq -n \
          --arg op "clone" \
          --arg repo "$REPO" \
          --arg path "$TARGET_DIR" \
          --arg output "$RESULT" \
          --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, repo: $repo, path: $path, exit_code: $code, output: $output}'
        ;;
        
      fetch)
        WDIR="''${2:-.}"
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        RESULT=$(git fetch --all 2>&1) || EXIT_CODE=$?
        
        jq -n --arg op "fetch" --arg dir "$WDIR" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
        ;;
        
      pull)
        WDIR="."
        REBASE=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--rebase" ]]; then REBASE="--rebase"
          else WDIR="$arg"
          fi
        done
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        RESULT=$(git pull $REBASE 2>&1) || EXIT_CODE=$?
        
        jq -n --arg op "pull" --arg dir "$WDIR" --arg rebase "$REBASE" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, dir: $dir, rebase: ($rebase != ""), exit_code: $code, output: $output}'
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
          else
            WDIR="$arg"
          fi
        done

        [[ -z "$MSG" ]] && fail "commit needs a message. Usage: git-agent commit <message> [--all|-a] [dir]" 1
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR" "$MSG"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        if [[ "$STAGED" == "--all" ]]; then
          git add --all 2>/dev/null || true
        fi
        
        EXIT_CODE=0
        RESULT=$(git commit -m "$MSG" 2>&1) || EXIT_CODE=$?
        
        if [[ $EXIT_CODE -eq 0 ]]; then
          HASH=$(git log -1 --format=%H)
          jq -n --arg op "commit" --arg hash "$HASH" --arg msg "$MSG" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
             '{success: true, operation: $op, hash: $hash, message: $msg, exit_code: $code, output: $output}'
        else
          jq -n --arg op "commit" --arg msg "$MSG" --arg error "$RESULT" --argjson code "$EXIT_CODE" \
             '{success: false, operation: $op, message: $msg, exit_code: $code, error: $error}'
        fi
        ;;
        
      status)
        WDIR="."
        SHORT=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--short" || "$arg" == "-s" ]]; then SHORT="--short"
          else WDIR="$arg"
          fi
        done
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        RESULT=$(git status $SHORT 2>&1) || EXIT_CODE=$?
        
        jq -n --arg op "status" --arg dir "$WDIR" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
        ;;
        
      diff)
        OPT=""
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ "$arg" == "--cached" ]]; then OPT="--cached"
          else WDIR="$arg"
          fi
        done
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        RESULT=$(git diff $OPT 2>&1) || EXIT_CODE=$?
        
        jq -n --arg op "diff" --arg dir "$WDIR" --arg cached "$OPT" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, dir: $dir, cached: ($cached == "--cached"), exit_code: $code, output: $output}'
        ;;
        
      log)
        NUM=10
        WDIR="."
        for arg in "''${@:2}"; do
          if [[ "$arg" =~ ^-n[0-9]+$ ]]; then NUM="''${arg#-n}"
          elif [[ "$arg" == "--oneline" ]]; then : 
          else WDIR="$arg"
          fi
        done
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        LOG_TMP=$(mktemp)
        ERR_TMP=$(mktemp)
        
        git log -n "$NUM" --format="%H%x00%an%x00%ai%x00%s" > "$LOG_TMP" 2> "$ERR_TMP" || EXIT_CODE=$?
        
        if [[ $EXIT_CODE -eq 0 ]]; then
          ENTRIES_JSON=$(cat "$LOG_TMP" | jq -Rs -c '[split("\n")[] | select(length > 0) | split("\u0000") | {hash: .[0], author: .[1], date: .[2], message: .[3]}]')
          jq -n --arg op "log" --arg dir "$WDIR" --argjson count "$NUM" --argjson entries "$ENTRIES_JSON" --argjson code "$EXIT_CODE" \
             '{success: true, operation: $op, dir: $dir, count: $count, exit_code: $code, entries: $entries}'
        else
          jq -n --arg op "log" --arg dir "$WDIR" --arg error "$(cat "$ERR_TMP")" --argjson code "$EXIT_CODE" \
             '{success: false, operation: $op, dir: $dir, exit_code: $code, error: $error}'
        fi
        rm -f "$LOG_TMP" "$ERR_TMP"
        ;;
        
      branch)
        WDIR="."
        ALLB=""
        VERBOSE=""
        for arg in "''${@:2}"; do
          if [[ "$arg" == "-a" || "$arg" == "--all" ]]; then ALLB="-a"
          elif [[ "$arg" == "-v" || "$arg" == "--verbose" ]]; then VERBOSE="-v"
          else WDIR="$arg"
          fi
        done
        
        WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
        check_push "$WDIR"
        [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1
        cd "$WDIR"
        
        EXIT_CODE=0
        RESULT=$(git branch $ALLB $VERBOSE 2>&1) || EXIT_CODE=$?
        
        jq -n --arg op "branch" --arg dir "$WDIR" --arg output "$RESULT" --argjson code "$EXIT_CODE" \
          '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, branches: $output}'
        ;;
        
      *)
        fail "Unknown operation: $OP. Use clone, fetch, pull, commit, status, diff, log, or branch" 1
        ;;
    esac
  '';
}
