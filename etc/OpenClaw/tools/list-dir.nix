# OpenClaw Tool: list-dir
#
# Lists directory contents within the OpenClaw workspace.
# Returns structured JSON with file metadata.

{
  pkgs,
  cfg,
  ...
}:

{
  name = "list-dir";
  description = "List directory contents in the OpenClaw workspace";
  permissions = "0750";

  usage = "list-dir [path] [--recursive|-r] [--hidden|-a] [--long|-l]";

  arguments = [
    {
      name = "path";
      desc = "Directory to list";
      default = "workspace root";
    }
    {
      name = "--recursive";
      desc = "Traverse subdirectories";
      default = "false";
    }
    {
      name = "--hidden";
      desc = "Show hidden files (excluding config)";
      default = "false";
    }
    {
      name = "--long";
      desc = "Include size, permissions, and timestamps";
      default = "false";
    }
  ];

  examples = [
    "list-dir my-project"
    "list-dir my-project/src --recursive"
    "list-dir . --long --hidden"
  ];

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
    CONFIG_DIR="$WORKSPACE/.openclaw"
    MAX_DEPTH=5
    MAX_ITEMS=1000

    DIR_PATH="."
    RECURSIVE=false
    SHOW_HIDDEN=false
    LONG_FORMAT=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --recursive|-r) RECURSIVE=true ;;
        --hidden|-a) SHOW_HIDDEN=true ;;
        --long|-l) LONG_FORMAT=true ;;
        -*)
          echo '{"error":"Unknown option"}' >&2
          exit 1
          ;;
        *)
          DIR_PATH="$1"
          ;;
      esac
      shift
    done

    [[ "$DIR_PATH" != /* ]] && DIR_PATH="$WORKSPACE/$DIR_PATH"
    TARGET="$(readlink -f "$DIR_PATH")"

    if [[ ! "$TARGET" =~ ^"$WORKSPACE"(/|$) ]]; then
      echo '{"error":"Access denied"}' >&2
      exit 2
    fi

    if [[ "$TARGET" == "$CONFIG_DIR"* ]]; then
      echo '{"error":"Access denied"}' >&2
      exit 2
    fi

    [[ ! -d "$TARGET" ]] && { echo '{"error":"Not a directory"}' >&2; exit 1; }

    RESULTS="[]"
    COUNT=0

    add_entry() {
      local path="$1"
      local name
      name="$(basename "$path")"

      [[ "$SHOW_HIDDEN" != true && "$name" == .* ]] && return

      if [[ -d "$path" ]]; then type="directory"
      elif [[ -L "$path" ]]; then type="symlink"
      else type="file"
      fi

      if [[ "$LONG_FORMAT" == true ]]; then
        size=$(stat -c%s "$path" 2>/dev/null || echo 0)
        mtime=$(stat -c%Y "$path" 2>/dev/null || echo 0)
        mode=$(stat -c%a "$path" 2>/dev/null || echo 000)

        entry=$(jq -n \
          --arg n "$name" \
          --arg t "$type" \
          --argjson s "$size" \
          --argjson m "$mtime" \
          --arg mo "$mode" \
          '{name:$n,type:$t,size:$s,mtime:$m,mode:$mo}')
      else
        entry=$(jq -n --arg n "$name" --arg t "$type" '{name:$n,type:$t}')
      fi

      RESULTS=$(echo "$RESULTS" | jq --argjson e "$entry" '. += [$e]')
    }

    if [[ "$RECURSIVE" == true ]]; then
      while IFS= read -r path; do
        count=$((count+1))
        [[ $COUNT -gt $MAX_ITEMS ]] && break

        [[ "$path" == "$CONFIG_DIR"* ]] && continue
        add_entry "$path"

      done < <(find "$TARGET" -mindepth 1 -maxdepth "$MAX_DEPTH")
    else
      while IFS= read -r path; do
        count=$((count+1))
        [[ $COUNT -gt $MAX_ITEMS ]] && break

        [[ "$path" == "$CONFIG_DIR"* ]] && continue
        add_entry "$path"

      done < <(find "$TARGET" -mindepth 1 -maxdepth 1)
    fi

    REL="''${TARGET#$WORKSPACE}"
    [[ -z "$REL" ]] && REL="/"

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
  '';
}
