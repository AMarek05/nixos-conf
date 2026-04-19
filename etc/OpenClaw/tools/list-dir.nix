# OpenClaw Tool: list-dir
#
# Lists directory contents within the OpenClaw workspace.
# Returns structured JSON with file metadata.

{
  config,
  lib,
  pkgs,
  cfg,
  ...
}:

{
  name = "list-dir";
  description = "List directory contents in the OpenClaw workspace";
  permissions = "0750";

  dependencies = with pkgs; [
    coreutils
    jq
  ];

  script = ''
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

    WORKSPACE="${cfg.workspace}"
    MAX_DEPTH=5
    MAX_ITEMS=1000

    # Parse arguments
    DIR_PATH=""
    RECURSIVE=false
    SHOW_HIDDEN=false
    LONG_FORMAT=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --recursive|-r)
          RECURSIVE=true
          shift
          ;;
        --hidden|-a)
          SHOW_HIDDEN=true
          shift
          ;;
        --long|-l)
          LONG_FORMAT=true
          shift
          ;;
        -*)
          echo "{\"error\": \"Unknown option: $1\"}" >&2
          exit 1
          ;;
        *)
          if [[ -z "$DIR_PATH" ]]; then
            DIR_PATH="$1"
          else
            echo "{\"error\": \"Unexpected argument: $1\"}" >&2
            exit 1
          fi
          shift
          ;;
      esac
    done

    # Default to workspace root
    DIR_PATH="''${DIR_PATH:-.}"

    # Resolve and validate path
    resolve_path() {
      local input_path="$1"
      
      # Handle relative paths
      if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
      fi
      
      # Canonicalize
      local resolved
      resolved="$(readlink -f "$input_path")"
      
      # Validate it's within workspace
      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        return 2
      fi
      
      echo "$resolved"
    }

    # Format single file entry
    format_entry() {
      local path="$1"
      local name
      name="$(basename "$path")"
      
      # Skip hidden files unless requested
      if [[ "$SHOW_HIDDEN" != true && "$name" == .* ]]; then
        return
      fi
      
      local type="file"
      if [[ -d "$path" ]]; then
        type="directory"
      elif [[ -L "$path" ]]; then
        type="symlink"
      fi
      
      if [[ "$LONG_FORMAT" == true ]]; then
        local size mtime mode
        size="$(stat -c%s "$path" 2>/dev/null || echo "0")"
        mtime="$(stat -c%Y "$path" 2>/dev/null || echo "0")"
        mode="$(stat -c%a "$path" 2>/dev/null || echo "000")"
        
        printf '    {"name": "%s", "type": "%s", "size": %s, "mtime": %s, "mode": "%s"}' \
          "$name" "$type" "$size" "$mtime" "$mode"
      else
        printf '    {"name": "%s", "type": "%s"}' "$name" "$type"
      fi
    }

    # List directory recursively
    list_recursive() {
      local dir="$1"
      local depth="''${2:-0}"
      local prefix="''${3:-""}"
      local count=0
      
      if [[ $depth -gt $MAX_DEPTH ]]; then
        return
      fi
      
      local entries
      entries=($(ls -1 "$dir" 2>/dev/null | sort))
      
      for entry in "''${entries[@]}"; do
        ((count++))
        if [[ $count -gt $MAX_ITEMS ]]; then
          echo '    {"warning": "Max items reached, truncating"}'
          return
        fi
        
        local full_path="$dir/$entry"
        local rel_path="''${prefix}''${entry}"
        
        # Skip hidden unless requested
        if [[ "$SHOW_HIDDEN" != true && "$entry" == .* ]]; then
          continue
        fi
        
        local type="file"
        if [[ -d "$full_path" ]]; then
          type="directory"
        elif [[ -L "$full_path" ]]; then
          type="symlink"
        fi
        
        if [[ "$LONG_FORMAT" == true ]]; then
          local size mtime mode
          size="$(stat -c%s "$full_path" 2>/dev/null || echo "0")"
          mtime="$(stat -c%Y "$full_path" 2>/dev/null || echo "0")"
          mode="$(stat -c%a "$full_path" 2>/dev/null || echo "000")"
          
          printf '    {"name": "%s", "path": "%s", "type": "%s", "size": %s, "mtime": %s, "mode": "%s"}' \
            "$entry" "$rel_path" "$type" "$size" "$mtime" "$mode"
        else
          printf '    {"name": "%s", "path": "%s", "type": "%s"}' \
            "$entry" "$rel_path" "$type"
        fi
        echo ","
        
        if [[ -d "$full_path" && ! -L "$full_path" ]]; then
          list_recursive "$full_path" $((depth + 1)) "$rel_path/"
        fi
      done
    }

    # Main logic
    main() {
      local target_path
      
      target_path="$(resolve_path "$DIR_PATH")" || {
        local ret=$?
        case $ret in
          2) echo "{\"error\": \"Access denied: path outside workspace\"}" >&2 ;;
          *) echo "{\"error\": \"Directory not found: $DIR_PATH\"}" >&2 ;;
        esac
        exit 1
      }
      
      if [[ ! -d "$target_path" ]]; then
        echo "{\"error\": \"Not a directory: $DIR_PATH\"}" >&2
        exit 1
      fi
      
      local rel_path="''${target_path#$WORKSPACE}"
      [[ -z "$rel_path" ]] && rel_path="/"
      
      if [[ "$RECURSIVE" == true ]]; then
        echo "{"
        echo "  \"success\": true,"
        echo "  \"path\": \"$target_path\","
        echo "  \"relative_path\": \"$rel_path\","
        echo "  \"recursive\": true,"
        echo "  \"entries\": ["
        list_recursive "$target_path"
        echo "  ]"
        echo "}"
      else
        echo "{"
        echo "  \"success\": true,"
        echo "  \"path\": \"$target_path\","
        echo "  \"relative_path\": \"$rel_path\","
        echo "  \"entries\": ["
        
        local entries
        entries=($(ls -1 "$target_path" 2>/dev/null | sort))
        local count=0
        
        for entry in "''${entries[@]}"; do
          ((count++))
          if [[ $count -gt $MAX_ITEMS ]]; then
            echo '    {"warning": "Max items reached, truncating"},'
            break
          fi
          format_entry "$target_path/$entry"
          echo ","
        done
        
        echo "  ]"
        echo "}"
      fi
    }

    main
  '';
}
