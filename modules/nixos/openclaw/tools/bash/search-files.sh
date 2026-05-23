#!/usr/bin/env bash
# OpenClaw Tool: search-files
# Description: Search for files or content in the OpenClaw workspace
# Usage: search-files <pattern> [--path <dir>] [--type <type>] [--max-results <n>] [--content|-c] [--case-sensitive|-s]

set -euo pipefail

WORKSPACE="${WORKSPACE:-$(pwd)}"

# Standardized JSON error response handler
fail() {
    local text="${1:-Unknown error}"
    local code="${2:-1}"
    jq -n --arg error "$text" --argjson code "$code" \
        '{success: false, exit_code: $code, error: $error}'
    exit "$code"
}

resolve_path() {
    local user_path="${1:-.}"
    local resolved
    resolved=$(realpath -m "$user_path")

    if [[ "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "$resolved"
    else
        return 1
    fi
}

MAX_RESULTS=100
PATTERN=""
SEARCH_PATH="."
FILE_TYPE=""
CONTENT_SEARCH=false
CASE_SENSITIVE=false

# Parse arguments (Standard space-separated)
while [[ $# -gt 0 ]]; do
    case "$1" in
    --path)
        SEARCH_PATH="$2"
        shift 2
        ;;
    --type)
        FILE_TYPE="$2"
        shift 2
        ;;
    --max-results)
        MAX_RESULTS="$2"
        shift 2
        ;;
    --content | -c)
        CONTENT_SEARCH=true
        shift 1
        ;;
    --case-sensitive | -s)
        CASE_SENSITIVE=true
        shift 1
        ;;
    -*) fail "Unknown option: $1" 1 ;;
    *)
        if [[ -z "$PATTERN" ]]; then
            PATTERN="$1"
        else
            fail "Unexpected argument: $1" 1
        fi
        shift 1
        ;;
    esac
done

[[ -z "$PATTERN" ]] && fail "Missing search pattern." 1

# Resolve and verify boundary
TARGET=$(resolve_path "$SEARCH_PATH") || fail "Access denied: Path is outside workspace ($WORKSPACE)" 2

[[ ! -d "$TARGET" ]] && fail "Path not found or is not a directory: $TARGET" 1

RESULTS_JSON="[]"
TMP_OUT=$(mktemp)
trap 'rm -f "$TMP_OUT"' EXIT

if [[ "$CONTENT_SEARCH" == true ]]; then
    # RIPGREP: CONTENT SEARCH
    RG_ARGS=("--no-ignore" "--json" "--max-count" "$MAX_RESULTS")
    [[ "$CASE_SENSITIVE" != true ]] && RG_ARGS+=(--ignore-case)

    # rg exits with 1 if no matches are found, which breaks pipefail.
    # We disable e temporarily to capture the output safely.
    set +e
    rg "${RG_ARGS[@]}" -- "$PATTERN" "$TARGET" >"$TMP_OUT"
    set -e

    if [[ -s "$TMP_OUT" ]]; then
        # Slurp ripgrep's JSON lines, extract the matches, and format the path to be workspace-relative
        RESULTS_JSON=$(jq -s -c --arg ws "$WORKSPACE/" '
            [ .[] | select(.type == "match") | 
            {
                path: (.data.path.text | sub("^" + $ws; "")),
                line: .data.line_number,
                content: (.data.lines.text | rtrimstr("\n"))
            } ]
        ' "$TMP_OUT")
    fi

else
    # FD: FILENAME SEARCH
    FD_ARGS=("--no-ignore" "--color" "never" "--absolute-path" "--exclude" ".git")
    [[ "$CASE_SENSITIVE" == true ]] && FD_ARGS+=("--case-sensitive") || FD_ARGS+=("--ignore-case")

    case "$FILE_TYPE" in
    file) FD_ARGS+=("--type" "f") ;;
    dir | directory) FD_ARGS+=("--type" "d") ;;
    symlink) FD_ARGS+=("--type" "l") ;;
    esac

    COUNT=0
    # fd exits with 0 even if no results, so it's pipefail safe.
    while IFS= read -r filepath; do
        [[ $COUNT -ge $MAX_RESULTS ]] && break

        # Format to relative path
        rel_path="${filepath#"$WORKSPACE"/}"
        [[ "$rel_path" == "$filepath" ]] && rel_path="."

        if [[ -d "$filepath" ]]; then
            ftype="directory"
        elif [[ -L "$filepath" ]]; then
            ftype="symlink"
        else
            ftype="file"
        fi

        jq -n -c --arg p "$rel_path" --arg t "$ftype" '{path: $p, type: $t}' >>"$TMP_OUT"

        COUNT=$((COUNT + 1))
    done < <(fd "${FD_ARGS[@]}" "$PATTERN" "$TARGET" 2>/dev/null || true)

    if [[ -s "$TMP_OUT" ]]; then
        RESULTS_JSON=$(jq -s -c '.' "$TMP_OUT")
    fi
fi

COUNT=$(echo "$RESULTS_JSON" | jq 'length')

# Final standardized output envelope
jq -n \
    --arg pattern "$PATTERN" \
    --arg path "${TARGET#"$WORKSPACE"/}" \
    --arg type "$([[ "$CONTENT_SEARCH" == true ]] && echo content || echo filename)" \
    --argjson count "$COUNT" \
    --argjson max "$MAX_RESULTS" \
    --argjson results "$RESULTS_JSON" \
    '{
        success: true,
        pattern: $pattern,
        search_path: (if $path == "" then "." else $path end),
        search_type: $type,
        results_count: $count,
        max_results: $max,
        results: $results
    }'
