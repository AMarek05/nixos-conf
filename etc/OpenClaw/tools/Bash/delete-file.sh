#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-$(pwd)}"

# Delete files or directories in the OpenClaw workspace (trashes by default)
#
# **Usage:**
#   `delete-file <path> [--recursive|-r] [--force|-f] [--permanent]`
#
# | Argument      | Description                                            | Default    |
# |---------------|--------------------------------------------------------|------------|
# | `path`        | Path to file or directory to delete                    | `required` |
# | `--recursive` | Required to delete directories                         | `false`    |
# | `--force`     | Skip confirmation prompt for directories               | `false`    |
# | `--permanent` | Permanently delete instead of trashing (irreversible!) | `false`    |
#
# **Examples:**
#   * `delete-file my-project/old-script.py`
#   * `delete-file abandoned-project --recursive`
#   * `delete-file sensitive-data.log --permanent --force`

# Parse arguments
PATH_ARG=""
RECURSIVE=false
FORCE=false
PERMANENT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --recursive|-r|-R) RECURSIVE=true; shift ;;
    --force|-f) FORCE=true; shift ;;
    --permanent) PERMANENT=true; shift ;;
    -*) echo "{\"error\": \"Unknown option: $1\"}" >&2; exit 1 ;;
    *)
      if [[ -z "$PATH_ARG" ]]; then PATH_ARG="$1"
      else echo "{\"error\": \"Unexpected argument: $1\"}" >&2; exit 1
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
  echo "$resolved"
}

# Check if path is protected (workspace root only)
is_protected() {
  local path="$1"
  if [[ "$path" == "$WORKSPACE" || "$path" == "$WORKSPACE/" ]]; then
    return 0
  fi
  return 1
}

# JSON-escape a string
json_escape() { printf '%s' "$1" | jq -Rs .; }

# Main logic
main() {
  local target_path
  target_path="$(resolve_path "$PATH_ARG")" || {
    local ret=$?
    case $ret in
      2) echo '{"error": "Access denied: path outside workspace"}' >&2 ;;
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

  # Check -L BEFORE -d (symlinks-to-dirs reported as symlinks, not directories)
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

  # Confirmation for directories without --force
  if [[ "$type" == "directory" && "$FORCE" != true && -t 0 ]]; then
    echo "WARNING: About to delete directory: $PATH_ARG" >&2
    echo "Use --force to skip this confirmation." >&2
    echo '{"error": "Deletion of directories requires --force flag in interactive mode"}' >&2
    exit 1
  fi

  # Get info before deletion
  local size=0
  local file_count=0
  if [[ "$type" == "directory" ]]; then
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
      rm -f "$target_path"
    elif [[ "$type" == "directory" ]]; then
      rm -rf --preserve-root "$target_path"
    else
      rm -f "$target_path"
    fi
  else
    # Default to trash (recoverable)
    trash-put "$target_path"
  fi

  # Verify deletion
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    echo "{\"error\": \"Failed to delete: $PATH_ARG\"}" >&2
    exit 2
  fi

  # Safe JSON output
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
