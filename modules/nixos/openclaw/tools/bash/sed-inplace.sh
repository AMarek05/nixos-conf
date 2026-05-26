#!/usr/bin/env bash
# OpenClaw Tool: sed-inplace
# Description: In-place line editing via GNU sed. Delete/replace/insert without rewriting entire files.
# Status: REVIEWED

set -euo pipefail

# Ensure environment variables are set (with fallbacks for standalone testing)
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

FILE=""
OP=""
ARG1=""
ARG2=""

# Parse arguments flexibly
while [[ $# -gt 0 ]]; do
    case "$1" in
    --delete)
        OP="delete"
        ARG1="${2:-}"
        shift 2
        ;;
    --replace)
        OP="replace"
        ARG1="${2:-}"
        ARG2="${3:-}"
        shift 3
        ;;
    --insert)
        OP="insert"
        ARG1="${2:-}"
        ARG2="${3:-}"
        shift 3
        ;;
    --substitute)
        OP="substitute"
        ARG1="${2:-}"
        shift 2
        ;;
    -*) fail "Unknown option: $1" 1 ;;
    *)
        if [[ -z "$FILE" ]]; then
            FILE="$1"
        else
            fail "Unexpected argument: $1" 1
        fi
        shift 1
        ;;
    esac
done

[[ -z "$FILE" ]] && fail "Missing target file." 1
[[ -z "$OP" ]] && fail "Missing operation. Use --delete, --replace, --insert, or --substitute." 1

# Resolve path and verify boundaries
TARGET=$(resolve_path "$FILE") || fail "Access denied: Path is outside workspace ($WORKSPACE)" 2

if [[ ! -f "$TARGET" ]]; then
    fail "File not found or is not a regular file: $TARGET" 1
fi

# Calculate the relative path for clean JSON output
REL_PATH="${TARGET#"$WORKSPACE"/}"
[[ "$REL_PATH" == "$TARGET" ]] && REL_PATH="."

# Execute the requested sed operation
case "$OP" in
delete)
    [[ -z "$ARG1" ]] && fail "Usage: --delete <range> (e.g., '5' or '5,10')" 1
    sed -i "${ARG1}d" "$TARGET"
    LINES=$(wc -l <"$TARGET")

    jq -n --arg op "delete" --arg range "$ARG1" --arg file "$REL_PATH" --argjson remaining "$LINES" \
        '{success: true, operation: $op, file: $file, range: $range, remaining_lines: $remaining}'
    ;;

replace)
    [[ -z "$ARG1" || -z "$ARG2" ]] && fail "Usage: --replace <pattern> <replacement>" 1
    # Using | as the delimiter. If pattern contains |, user should use --substitute
    sed -i "s|${ARG1}|${ARG2}|g" "$TARGET"

    jq -n --arg op "replace" --arg pat "$ARG1" --arg rep "$ARG2" --arg file "$REL_PATH" \
        '{success: true, operation: $op, file: $file, pattern: $pat, replacement: $rep}'
    ;;

insert)
    [[ -z "$ARG1" || -z "$ARG2" ]] && fail "Usage: --insert <linenum> <text>" 1
    # Use GNU sed 'i' command to insert BEFORE the given line number
    sed -i "${ARG1}i\\${ARG2}" "$TARGET"

    jq -n --arg op "insert" --argjson line "$ARG1" --arg file "$REL_PATH" \
        '{success: true, operation: $op, file: $file, at_line: $line}'
    ;;

substitute)
    [[ -z "$ARG1" ]] && fail "Usage: --substitute <sed-expression>" 1
    sed -i "$ARG1" "$TARGET"

    jq -n --arg op "substitute" --arg expr "$ARG1" --arg file "$REL_PATH" \
        '{success: true, operation: $op, file: $file, expression: $expr}'
    ;;
esac
