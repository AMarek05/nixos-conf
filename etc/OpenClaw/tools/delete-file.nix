# OpenClaw Tool: delete-file
#
# Safely deletes files or directories within the OpenClaw workspace.
# Includes safety checks to prevent accidental data loss.

{
  config,
  lib,
  pkgs,
  cfg,
  ...
}:

{
  name = "delete-file";
  description = "Delete files or directories in the OpenClaw workspace";
  permissions = "0750";

  dependencies = with pkgs; [
    coreutils
    jq
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: delete-file
    # Description: Delete files or directories in the OpenClaw workspace
    #
    # Usage: delete-file <path> [--recursive] [--force]
    #
    # Arguments:
    #   path        - Path to file or directory to delete
    #   --recursive - Required for directories
    #   --force     - Skip confirmation (use with caution)
    #
    # Output:
    #   JSON object with result or error
    #
    # Examples:
    #   delete-file workspace/old-file.txt
    #   delete-file workspace/old-folder --recursive
    #
    # Exit codes:
    #   0 - Success
    #   1 - Invalid input or file not found
    #   2 - Permission denied or outside workspace

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"

    # Protected paths that cannot be deleted
    PROTECTED_PATHS=(
      "$WORKSPACE"
      "$WORKSPACE/.openclaw"
      "$WORKSPACE/tools"
      "$WORKSPACE/workspace"
    )

    # Parse arguments
    PATH_ARG=""
    RECURSIVE=false
    FORCE=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --recursive|-r|-R)
          RECURSIVE=true
          shift
          ;;
        --force|-f)
          FORCE=true
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
      
      # Handle relative paths
      if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
      fi
      
      # Canonicalize
      local resolved
      if [[ -e "$input_path" ]]; then
        resolved="$(readlink -f "$input_path")"
      else
        resolved="$input_path"
      fi
      
      # Validate it's within workspace
      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        return 2
      fi
      
      echo "$resolved"
    }

    # Check if path is protected
    is_protected() {
      local path="$1"
      
      for protected in "''${PROTECTED_PATHS[@]}"; do
        if [[ "$path" == "$protected" ]]; then
          return 0
        fi
      done
      return 1
    }

    # Main logic
    main() {
      local target_path
      
      target_path="$(resolve_path "$PATH_ARG")" || {
        echo "{\"error\": \"Access denied: path outside workspace\"}" >&2
        exit 2
      }
      
      # Check if exists
      if [[ ! -e "$target_path" ]]; then
        echo "{\"error\": \"Path does not exist: $PATH_ARG\"}" >&2
        exit 1
      fi
      
      # Check if protected
      if is_protected "$target_path"; then
        echo "{\"error\": \"Cannot delete protected path: $PATH_ARG\"}" >&2
        exit 2
      fi
      
      # Determine type
      local type="file"
      if [[ -d "$target_path" ]]; then
        type="directory"
      elif [[ -L "$target_path" ]]; then
        type="symlink"
      fi
      
      # Check recursive flag for directories
      if [[ "$type" == "directory" && "$RECURSIVE" != true ]]; then
        echo "{\"error\": \"Cannot delete directory without --recursive flag\"}" >&2
        exit 1
      fi
      
      # Get info before deletion
      local size=0
      local file_count=0
      
      if [[ "$type" == "directory" ]]; then
        file_count="$(find "$target_path" -type f | wc -l)"
        size="$(du -sb "$target_path" | cut -f1)"
      else
        size="$(stat -c%s "$target_path" 2>/dev/null || echo "0")"
        file_count=1
      fi
      
      # Perform deletion
      if [[ "$type" == "directory" ]]; then
        rm -rf "$target_path"
      else
        rm -f "$target_path"
      fi
      
      # Verify deletion
      if [[ -e "$target_path" ]]; then
        echo "{\"error\": \"Failed to delete: $PATH_ARG\"}" >&2
        exit 2
      fi
      
      cat <<EOF
    {
      "success": true,
      "deleted_path": "$target_path",
      "relative_path": "$PATH_ARG",
      "type": "$type",
      "files_removed": $file_count,
      "bytes_freed": $size
    }
    EOF
    }

    main
  '';
}
