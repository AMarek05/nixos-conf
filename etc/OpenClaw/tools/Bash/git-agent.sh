#!/usr/bin/env bash

# Standardized JSON error response handler
fail() {
    local text="${1:-Unknown error}"
    local code="${2:-1}"
    jq -n --arg error "$text" --argjson code "$code" \
        '{success: false, exit_code: $code, error: $error}'
    exit "$code"
}

resolve_path() {
    local p="$1"

    p="$(realpath -m "$p")"

    if ! [[ "$p" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "Outside workspace: $p" >&2
        return 2
    fi
    echo "$p"
}

OP="${1:-}"
[[ -z $OP ]] && fail "Usage: git-agent <clone|fetch|pull|push|commit|checkout|create-branch|status|diff|log|branch> [args]" 1

# Shift past the operation (clone, fetch, etc.) so we can process flags
shift

case $OP in
clone)
    REPO=""
    TARGET_DIR=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -*)
            fail "Incorrect flag: $1" 1
            ;;
        *)
            if [[ -z "$REPO" ]]; then
                REPO="$1"
            fi
            shift
            ;;
        esac
    done

    [[ -z "$REPO" ]] && fail "clone needs a URL" 1

    if [[ -n "$TARGET_DIR" ]]; then
        TARGET_DIR="$(resolve_path "$TARGET_DIR")" || fail "Invalid target directory" 2
    else
        TARGET_DIR="$(basename "$REPO" .git)"
        TARGET_DIR="$WORKSPACE/git/$TARGET_DIR"
    fi
    mkdir -p "$(dirname "$TARGET_DIR")"

    EXIT_CODE=0
    RESULT=""

    # SSH handled naturally via exported GIT_SSH_COMMAND or system ssh-agent
    RESULT=$(git clone --recursive "$REPO" "$TARGET_DIR" 2>&1) || EXIT_CODE=$?

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
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

    EXIT_CODE=0
    RESULT=$(git fetch --all 2>&1) || EXIT_CODE=$?

    jq -n --arg op "fetch" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
        --arg output "$RESULT" \
        '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
    ;;

pull)
    WDIR="."
    REBASE=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --rebase)
            REBASE="--rebase"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

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

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --force | -f)
            FORCE="--force"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            if [[ -z "$REMOTE" ]]; then
                REMOTE="$1"
            elif [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            fi
            shift
            ;;
        esac
    done

    [[ -z "$REMOTE" ]] && REMOTE="origin"

    # If user runs `push feature-branch`, swap variables to `push origin feature-branch`
    if [[ -z "$BRANCH" && "$REMOTE" != "origin" ]]; then
        BRANCH="$REMOTE"
        REMOTE="origin"
    fi

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

    [[ -z "$BRANCH" ]] && BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    check_push_safe "$BRANCH"

    EXIT_CODE=0
    RESULT=$(git push $FORCE "$REMOTE" "$BRANCH" 2>&1) || EXIT_CODE=$?

    jq -n --arg op "push" --arg remote "$REMOTE" --arg branch "$BRANCH" \
        --argjson forced "$([[ -n "$FORCE" ]] && echo true || echo false)" \
        --argjson code "$EXIT_CODE" --arg output "$RESULT" \
        '{success: ($code == 0), operation: $op, remote: $remote, branch: $branch, forced: $forced, exit_code: $code, output: $output}'
    ;;

commit)
    MSG=""
    STAGED=""
    WDIR="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --all | -a)
            STAGED="--all"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            if [[ -z "$MSG" ]]; then
                MSG="$1"
            else
                [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            fi
            shift
            ;;
        esac
    done

    [[ -z "$MSG" ]] && fail "commit needs a message. Usage: git-agent commit <message> [--all|-a] [dir]" 1

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

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

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -b)
            CREATE=true
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            fi
            shift
            ;;
        esac
    done

    [[ -z "$BRANCH" ]] && fail "checkout needs a branch name. Usage: git-agent checkout <branch> [-b] [dir]" 1

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

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
    WDIR="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -*) fail "Incorrect flag: $1" 1 ;; # ignoring flags like -b if erroneously passed
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            fi
            shift
            ;;
        esac
    done

    [[ -z "$BRANCH" ]] && fail "create-branch needs a name. Usage: git-agent create-branch <branch> [base-branch] [dir]" 1

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

    EXIT_CODE=0
    RESULT=$(git checkout -b "$BRANCH" 2>&1) || EXIT_CODE=$?

    jq -n --arg op "create-branch" --arg branch "$BRANCH" \
        --argjson code "$EXIT_CODE" --arg output "$RESULT" \
        '{success: ($code == 0), operation: $op, branch: $branch, exit_code: $code, output: $output}'
    ;;

status)
    WDIR="."
    SHORT=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --short | -s)
            SHORT="--short"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

    EXIT_CODE=0
    RESULT=$(git status $SHORT 2>&1) || EXIT_CODE=$?

    jq -n --arg op "status" --arg dir "$WDIR" --argjson code "$EXIT_CODE" \
        --arg output "$RESULT" \
        '{success: ($code == 0), operation: $op, dir: $dir, exit_code: $code, output: $output}'
    ;;

diff)
    OPT=""
    WDIR="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --cached)
            OPT="--cached"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

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

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -n)
            # Catch `-n 5` format
            NUM="$2"
            shift 2
            ;;
        -n*)
            # Catch legacy `-n5` format safely
            NUM="${1#-n}"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

    EXIT_CODE=0
    LOG_TMP=$(mktemp)
    ERR_TMP=$(mktemp)

    git log -n "$NUM" --format="%H%x00%an%x00%ai%x00%s" >"$LOG_TMP" 2>"$ERR_TMP" || EXIT_CODE=$?

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

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -a | --all)
            ALLB="-a"
            shift
            ;;
        -v | --verbose)
            VERBOSE="-v"
            shift
            ;;
        -*) fail "Incorrect flag: $1" 1 ;;
        *)
            [[ "$1" != "." || "$WDIR" == "." ]] && WDIR="$1"
            shift
            ;;
        esac
    done

    WDIR="$(resolve_path "$WDIR")" || fail "Invalid directory" 2
    [[ -d "$WDIR/.git" ]] || fail "Not a git repo: $WDIR" 1

    cd "$WDIR" || fail "cd failed." "$?"

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
