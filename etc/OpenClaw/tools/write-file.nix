# OpenClaw Tool: write-file
#
# Safely writes a file within the OpenClaw workspace.
# Content is read from stdin to avoid shell interpretation issues.
# Supports text and binary content with various encodings.
{
  pkgs,
  cfg,
  ...
}:

{
  name = "write-file";
  description = "Create, overwrite, or append to files in the workspace. Content is read from stdin.";
  permissions = "0750";
  usage = "write-file <path> [--append] [--mkdir] [--mode=MODE] [--encoding=ENC] < content";
  arguments = [
    {
      name = "path";
      desc = "Relative or absolute path to file (required)";
      default = "required";
    }
    {
      name = "--append";
      desc = "Append content to the end of the file";
      default = "false";
    }
    {
      name = "--mkdir";
      desc = "Automatically create missing parent directories";
      default = "false";
    }
    {
      name = "--mode";
      desc = "Octal file permissions (e.g., 0755)";
      default = "0644";
    }
    {
      name = "--encoding";
      desc = "Payload encoding on stdin: text, base64, hex";
      default = "text";
    }
  ];
  examples = [
    "write-file my-project/TODO.md < todo.txt"
    "echo '{\"key\": \"value\"}' | write-file data.json --mkdir"
    "cat script.sh | write-file my-project/script.sh --mode=0755"
    "base64-content | write-file image.png --encoding=base64"
  ];

  dependencies = with pkgs; [
    coreutils
    jq
    xxd
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: write-file (v2 — stdin-based)
    #
    # DESIGN CHANGE FROM v1:
    #   Content is read from stdin, NOT passed as a positional argument.
    #   This avoids ALL shell interpretation issues with file content.
    #   The old design ($2 as content) broke on any content containing
    #   $, backticks, !, unbalanced quotes, Nix '''' escapes, etc.
    #
    # Usage: write-file <path> [options] < content
    #   echo "hello" | write-file greeting.txt
    #   write-file notes.txt < notes.txt
    #   base64-data | write-file binary.bin --encoding=base64

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"
    MAX_FILE_SIZE=$((10 * 1024 * 1024)) # 10MiB

    # Parse arguments
    PATH_ARG=""
    ENCODING="text"
    APPEND=false
    MODE="0644"
    MKDIR=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --encoding=*)  ENCODING="''${1#*=}"; shift ;;
        --append)      APPEND=true; shift ;;
        --mode=*)      MODE="''${1#*=}"; shift ;;
        --mkdir)       MKDIR=true; shift ;;
        -*)            echo "{\"error\": \"Unknown option: $1\"}" >&2; exit 1 ;;
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

    # Validate --mode is a proper octal
    if [[ ! "$MODE" =~ ^[0-7]{3,4}$ ]]; then
      echo "{\"error\": \"Invalid mode: $MODE (must be 3-4 digit octal, e.g., 0644)\"}" >&2
      exit 1
    fi

    # Validate --encoding
    case "$ENCODING" in
      text|utf-8|base64|hex) ;; # valid
      *) echo "{\"error\": \"Unknown encoding: $ENCODING (valid: text, base64, hex)\"}" >&2; exit 1 ;;
    esac

    # Secure Path Resolution
    resolve_path() {
      local input_path="$1"

      if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
      fi

      local resolved
      resolved="$(realpath -m "$input_path")"

      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        return 2
      fi

      if [[ "$resolved" == "$CONFIG_DIR"* ]]; then
        return 3
      fi

      echo "$resolved"
    }

    # JSON-escape a string
    json_escape() {
      printf '%s' "$1" | jq -Rs .
    }

    # Main logic
    main() {
      local target_path parent_dir
      target_path="$(resolve_path "$PATH_ARG")" || {
        local ret=$?
        case $ret in
          2) echo '{"error": "Access denied: path outside workspace"}' >&2 ;;
          3) echo '{"error": "Access denied: cannot modify .openclaw configuration"}' >&2 ;;
        esac
        exit "$ret"
      }

      parent_dir="$(dirname "$target_path")"

      # Create parent directories if needed
      if [[ ! -d "$parent_dir" ]]; then
        if [[ "$MKDIR" == true ]]; then
          mkdir -p "$parent_dir"
        else
          echo "{\"error\": \"Parent directory does not exist (use --mkdir to create)\"}" >&2
          exit 1
        fi
      fi

      # Read content from stdin into a temp file
      # This avoids ANY shell interpretation of the content
      local tmpfile
      tmpfile="$(mktemp)"

      # Read stdin with size limit
      local content_size=0
      local chunk_size=4096
      while IFS= read -r -n "$chunk_size" chunk; do
        printf '%s' "$chunk" >> "$tmpfile"
        content_size=$((content_size + ''${#chunk}))
        if [[ $content_size -gt $MAX_FILE_SIZE ]]; then
          rm -f "$tmpfile"
          echo "{\"error\": \"Content too large: exceeds $MAX_FILE_SIZE bytes\"}" >&2
          exit 1
        fi
      done

      # Decode if needed, writing to final target
      local write_op="created"
      if [[ -f "$target_path" ]]; then
        if [[ "$APPEND" == true ]]; then
          write_op="appended"
        else
          write_op="overwritten"
        fi
      fi

      local redirect=">"
      if [[ "$APPEND" == true ]]; then
        redirect=">>"
      fi

      case "$ENCODING" in
        text|utf-8)
          # Write raw from temp file — no printf, no trailing newline injection
          if [[ "$APPEND" == true ]]; then
            cat "$tmpfile" >> "$target_path"
          else
            cat "$tmpfile" > "$target_path"
          fi
          ;;
        base64)
          if [[ "$APPEND" == true ]]; then
            base64 -d < "$tmpfile" >> "$target_path"
          else
            base64 -d < "$tmpfile" > "$target_path"
          fi
          ;;
        hex)
          if [[ "$APPEND" == true ]]; then
            xxd -r -p < "$tmpfile" >> "$target_path"
          else
            xxd -r -p < "$tmpfile" > "$target_path"
          fi
          ;;
      esac

      # Cleanup temp file
      rm -f "$tmpfile"

      # Set permissions
      chmod "$MODE" "$target_path"

      # Get final file info
      local final_size final_mode escaped_path escaped_rel
      final_size="$(stat -c%s "$target_path")"
      final_mode="$(stat -c%a "$target_path")"
      escaped_path="$(json_escape "$target_path")"
      escaped_rel="$(json_escape "$PATH_ARG")"

      # Build output JSON safely with jq
      jq -n \
        --arg path "$target_path" \
        --arg rel "$PATH_ARG" \
        --arg op "$write_op" \
        --arg enc "$ENCODING" \
        --argjson size "$final_size" \
        --arg mode "$final_mode" \
        '{
          success: true,
          path: $path,
          relative_path: $rel,
          operation: $op,
          encoding: $enc,
          size_bytes: $size,
          mode: $mode
        }'
    }

    main
  '';
}
