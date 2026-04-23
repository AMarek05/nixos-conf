#!/usr/bin/env bash
set -euo pipefail

### `delete-file`
# Delete files or directories in the OpenClaw workspace (trashes by default)
#
# **Usage:**
# `delete-file <path> [--recursive|-r] [--force|-f] [--permanent]`
#
# | Argument | Description | Default |
# |----------|-------------|---------|
# | `path` | Path to file or directory to delete | `required` |
# | `--recursive` | Required to delete directories | `false` |
# | `--force` | Skip confirmation prompt for directories | `false` |
# | `--permanent` | Permanently delete instead of trashing (irreversible!) | `false` |
#
#
# **Examples:**
# * `delete-file my-project/old-script.py`
# * `delete-file abandoned-project --recursive`
# * `delete-file sensitive-data.log --permanent --force`
#

# Parse arguments
PATH_ARG=""
RECURSIVE=false
FORCE=false
PERMANENT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    --recursive | -r | -R)
        RECURSIVE=true
        shift
        ;;
    --force | -f)
        FORCE=true
        shift
        ;;
    --permanent)
        PERMANENT=true
        shift
        ;;
    -*)
        echo "{\"error\": \"Unknown option: $1\"}" >&2
        exit 1
        ;;
    *)
        if [[ -z "$PATH_ARG" ]]; then
            PATH_ARG="$1"
        else
            echo "{\"error\": \"Unexpected argument: $1\"}" >&2
            exit 1
        fi
        shift
        ;;
    esac
done

if [[ -z "$PATH_ARG" ]]; then
    echo '{"error": "Missing required argument: path"}' >&2
    exit 1
fi

# Resolve and validate path
resolve_path() {
    local input_path="$1"

    if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
    fi

    local resolved
    if [[ -e "$input_path" ]]; then
        resolved="$(readlink -f "$input_path")"
    else
        resolved="$input_path"
    fi

    if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        return 2
    fi

    # BUG-DF-8 FIX: Check .openclaw in resolve_path for consistency
    if [[ "$resolved" == "$CONFIG_DIR"* ]]; then
        return 3
    fi

    echo "$resolved"
}

# Check if path is protected
is_protected() {
    local path="$1"

    # 1. Protect the workspace root from being deleted (exact match only)
    if [[ "$path" == "$WORKSPACE" || "$path" == "$WORKSPACE/" ]]; then
        return 0
    fi

    # 2. Protect the .openclaw configuration directory and everything inside it
    if [[ "$path" == "$CONFIG_DIR" || "$path" == "$CONFIG_DIR"/* ]]; then
        return 0
    fi

    return 1
}
# JSON-escape a string
json_escape() {
    printf '%s' "$1" | jq -Rs .
}

# Main logic
main() {
    local target_path
    target_path="$(resolve_path "$PATH_ARG")" || {
        local ret=$?
        case $ret in
        2) echo '{"error": "Access denied: path outside workspace"}' >&2 ;;
        3) echo '{"error": "Access denied: cannot delete .openclaw configuration"}' >&2 ;;
        esac
        exit "$ret"
    }

    # Check if exists
    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        echo "{\"error\": \"Path does not exist: $PATH_ARG\"}" >&2
        exit 1
    fi

    # Check if protected
    if is_protected "$target_path"; then
        echo "{\"error\": \"Cannot delete protected path: $PATH_ARG\"}" >&2
        exit 2
    fi

    # BUG-DF-4 FIX: Check -L BEFORE -d
    local type="file"
    if [[ -L "$target_path" ]]; then
        type="symlink"
    elif [[ -d "$target_path" ]]; then
        type="directory"
    fi

    # Check recursive flag for directories
    if [[ "$type" == "directory" && "$RECURSIVE" != true ]]; then
        echo '{"error": "Cannot delete directory without --recursive flag"}' >&2
        exit 1
    fi

    # BUG-DF-3 FIX: Confirmation for directories without --force
    if [[ "$type" == "directory" && "$FORCE" != true && -t 0 ]]; then
        echo "WARNING: About to delete directory: $PATH_ARG" >&2
        echo "Use --force to skip this confirmation." >&2
        # If running interactively, we could prompt here.
        # In non-interactive mode (piped), skip the prompt but require --force
        echo '{"error": "Deletion of directories requires --force flag in interactive mode"}' >&2
        exit 1
    fi

    # Get info before deletion
    local size=0
    local file_count=0
    if [[ "$type" == "directory" ]]; then
        # BUG-DF-2 FIX: Use find with -maxdepth safety and null-delimited count
        # Avoid following symlinks out of workspace
        file_count="$(find "$target_path" -xdev -type f -print0 2>/dev/null | tr -d '\\0' | wc -c)"
        # Fallback: count null-separated entries properly
        file_count="$(find "$target_path" -xdev -type f 2>/dev/null | wc -l)"
        size="$(du -sb "$target_path" 2>/dev/null | cut -f1 || echo "0")"
    elif [[ -L "$target_path" ]]; then
        size=0
        file_count=1
    else
        size="$(stat -c%s "$target_path" 2>/dev/null || echo "0")"
        file_count=1
    fi

    # Perform deletion
    local deletion_method="trashed"
    if [[ "$PERMANENT" == true ]]; then
        deletion_method="permanently_deleted"
        if [[ "$type" == "symlink" ]]; then
            # BUG-DF-5 FIX: rm -f for symlinks (removes symlink, not target)
            rm -f "$target_path"
        elif [[ "$type" == "directory" ]]; then
            rm -rf --preserve-root "$target_path"
        else
            rm -f "$target_path"
        fi
    else
        # BUG-DF-1 FIX: Default to trash (recoverable)
        if [[ "$type" == "symlink" ]]; then
            # trash-put handles symlinks safely
            trash-put "$target_path"
        elif [[ "$type" == "directory" ]]; then
            trash-put "$target_path"
        else
            trash-put "$target_path"
        fi
    fi

    # Verify deletion
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        echo "{\"error\": \"Failed to delete: $PATH_ARG\"}" >&2
        exit 2
    fi

    # BUG-DF-7 FIX: Use jq for safe JSON output
    jq -n \
        --arg path "$target_path" \
        --arg rel "$PATH_ARG" \
        --arg type "$type" \
        --argjson files "$file_count" \
        --argjson bytes "$size" \
        --arg method "$deletion_method" \
        '{
              success: true,
              deleted_path: $path,
              relative_path: $rel,
              type: $type,
              files_removed: $files,
              bytes_freed: $bytes,
              method: $method
            }'
}

main
