#!/usr/bin/env bash
# OpenClaw Tool: list-dir
# Description: List directory contents in the OpenClaw workspace
#
# Usage: list-dir [path] [--recursive] [--hidden] [--long]
#
# Arguments:
#   path        - Directory path (default: workspace root)
#   --recursive - List subdirectories recursively
#   --hidden    - Show hidden files
#   --long      - Show detailed file info (size, date, permissions)
#
# Output:
#   JSON array of files/directories with metadata
#
# Examples:
#   list-dir workspace
#   list-dir workspace/projects --recursive
#   list-dir --long --hidden

set -euo pipefail

# Ensure environment variables are set (with fallbacks for standalone execution)
WORKSPACE="${WORKSPACE:-$(pwd)}"

MAX_DEPTH=5
MAX_ITEMS=1000

DIR_PATH="."
RECURSIVE=false
SHOW_HIDDEN=false
LONG_FORMAT=false

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
    # Expand to absolute path based on actual PWD
    local resolved
    resolved=$(realpath -m "$user_path")

    if [[ "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "$resolved"
    else
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --recursive | -r) RECURSIVE=true ;;
    --hidden | -a) SHOW_HIDDEN=true ;;
    --long | -l) LONG_FORMAT=true ;;
    -*) fail "Unknown option: $1" 1 ;;
    *) DIR_PATH="$1" ;;
    esac
    shift
done

# Resolve path handling relative paths safely against the workspace
TARGET=$(resolve_path "$DIR_PATH") || fail "Access denied: Path is outside workspace" 2

# Verify the target is actually a directory
if [[ ! -d "$TARGET" ]]; then
    fail "Not a directory: $TARGET" 1
fi

# Use a temporary file to accumulate JSON lines.
# This avoids the massive performance penalty of piping jq into itself inside a loop.
TMP_OUT=$(mktemp)
trap 'rm -f "$TMP_OUT"' EXIT

COUNT=0
FD_ARGS=("--color" "never" "--absolute-path")

if [[ "$RECURSIVE" == true ]]; then
    FD_ARGS+=("--max-depth" "$MAX_DEPTH")
else
    FD_ARGS+=("--max-depth" "1")
fi

FD_ARGS+=("--exclude" ".git")

# Usage:

# Read entries from find command
while IFS= read -r path; do
    # Enforce item limits
    if [[ $COUNT -ge $MAX_ITEMS ]]; then
        break
    fi

    name="$(basename "$path")"

    # Handle hidden files toggle
    if [[ "$SHOW_HIDDEN" != true && "$name" == .* ]]; then
        continue
    fi

    # Determine file type
    if [[ -L "$path" ]]; then
        type="symlink"
    elif [[ -d "$path" ]]; then
        type="directory"
    else
        type="file"
    fi

    # Calculate the path relative to the TARGET directory
    if [[ "$path" == "$TARGET" ]]; then
        rel_path="."
    else
        # Strip the TARGET path and the trailing slash from the beginning
        rel_path="${path#"$TARGET"/}"
    fi

    # Append safely escaped JSON lines to the temp file
    if [[ "$LONG_FORMAT" == true ]]; then
        size=$(stat -c%s "$path" 2>/dev/null || echo 0)
        mtime=$(stat -c%Y "$path" 2>/dev/null || echo 0)
        mode=$(stat -c%a "$path" 2>/dev/null || echo 000)

        jq -n -c \
            --arg n "$name" \
            --arg p "$rel_path" \
            --arg t "$type" \
            --argjson s "$size" \
            --argjson m "$mtime" \
            --arg mo "$mode" \
            '{name: $n, path: $p, type: $t, size: $s, mtime: $m, mode: $mo}' >>"$TMP_OUT"
    else
        jq -n -c \
            --arg n "$name" \
            --arg p "$rel_path" \
            --arg t "$type" \
            '{name: $n, path: $p, type: $t}' >>"$TMP_OUT"
    fi

    COUNT=$((COUNT + 1))
done < <(fd . "$TARGET" "${FD_ARGS[@]}")

# Format relative path for the output envelope
REL="${TARGET#"$WORKSPACE"}"
[[ -z "$REL" ]] && REL="/"

# Slurp all JSON lines from the temp file into a single JSON array
RESULTS=$(jq -s '.' "$TMP_OUT")

# Final Standardized Output
jq -n \
    --arg path "$TARGET" \
    --arg rel "$REL" \
    --argjson recursive "$RECURSIVE" \
    --argjson results "$RESULTS" \
    '{
        success: true,
        path: $path,
        relative_path: $rel,
        recursive: $recursive,
        entries: $results
    }'
