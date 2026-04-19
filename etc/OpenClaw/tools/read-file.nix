# OpenClaw Tool: read-file
#
# Safely reads a file within the OpenClaw workspace.
# Supports text files with optional encoding detection.
# Returns file contents as JSON for easy parsing by the agent.

{
  pkgs,
  cfg,
  ...
}:

{
  name = "read-file";
  description = "Read a file from the OpenClaw workspace";
  permissions = "0750";

  dependencies = with pkgs; [
    coreutils
    file
    jq
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: read-file
    # Description: Read a file from the OpenClaw workspace
    #
    # Usage: read-file <path> [--lines=N] [--offset=N] [--encoding=ENC]
    #
    # Arguments:
    #   path           - Relative or absolute path to file (within workspace)
    #   --lines=N      - Read only N lines (optional)
    #   --offset=N     - Start from line N (optional, requires --lines)
    #   --encoding=ENC - Force encoding (utf-8, base64, hex)
    #
    # Output:
    #   JSON object with file contents, metadata, or error
    #
    # Examples:
    #   read-file workspace/myfile.txt
    #   read-file workspace/data.json --lines=50
    #   read-file workspace/binary.bin --encoding=base64
    #
    # Exit codes:
    #   0 - Success
    #   1 - Invalid input or file not found
    #   2 - Permission denied or outside workspace

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    MAX_FILE_SIZE=$((10 * 1024 * 1024))  # 10MB max
    MAX_LINES=10000
    DEFAULT_LINES=1000

    # Parse arguments
    PATH_ARG=""
    LINES=""
    OFFSET=""
    ENCODING="auto"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --lines=*)
          LINES="''${1#*=}"
          shift
          ;;
        --offset=*)
          OFFSET="''${1#*=}"
          shift
          ;;
        --encoding=*)
          ENCODING="''${1#*=}"
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
      local resolved
      
      # Handle relative paths
      if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
      fi
      
      # Resolve to absolute path
      if [[ ! -e "$input_path" ]]; then
        return 1
      fi
      
      resolved="$(readlink -f "$input_path")"
      
      # Validate it's within workspace
      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        return 2
      fi
      
      echo "$resolved"
    }

    # Check file type
    detect_type() {
      local file="$1"
      file -b --mime-type "$file" 2>/dev/null || echo "application/octet-stream"
    }

    # Main logic
    main() {
      local target_path
      
      target_path="$(resolve_path "$PATH_ARG")" || {
        local ret=$?
        case $ret in
          1) echo "{\"error\": \"File not found: $PATH_ARG\"}" >&2 ;;
          2) echo "{\"error\": \"Access denied: path outside workspace\"}" >&2 ;;
        esac
        exit 1
      }
      
      # Check if it's a directory
      if [[ -d "$target_path" ]]; then
        echo "{\"error\": \"Path is a directory, not a file. Use 'list-dir' instead.\"}" >&2
        exit 1
      fi
      
      # Check file size
      local file_size
      file_size="$(stat -c%s "$target_path")"
      
      if [[ $file_size -gt $MAX_FILE_SIZE ]]; then
        echo "{\"error\": \"File too large: $file_size bytes (max $MAX_FILE_SIZE)\"}" >&2
        exit 1
      fi
      
      # Detect encoding
      local mime_type detected_encoding
      mime_type="$(detect_type "$target_path")"
      
      case "$ENCODING" in
        auto)
          if [[ "$mime_type" == text/* ]]; then
            detected_encoding="text"
          else
            detected_encoding="base64"
          fi
          ;;
        utf-8|text)
          detected_encoding="text"
          ;;
        base64|hex)
          detected_encoding="$ENCODING"
          ;;
        *)
          echo "{\"error\": \"Unknown encoding: $ENCODING\"}" >&2
          exit 1
          ;;
      esac
      
      # Read file content
      local content lines_read total_lines
      
      if [[ "$detected_encoding" == "text" ]]; then
        # Count total lines
        total_lines="$(wc -l < "$target_path")"
        
        # Determine lines to read
        local read_lines="''${LINES:-$DEFAULT_LINES}"
        [[ $read_lines -gt $MAX_LINES ]] && read_lines=$MAX_LINES
        
        # Read with optional offset
        if [[ -n "$OFFSET" ]]; then
          content="$(tail -n +"$((OFFSET + 1))" "$target_path" | head -n "$read_lines")"
        else
          content="$(head -n "$read_lines" "$target_path")"
        fi
        
        lines_read="$(echo "$content" | wc -l)"

        # Build JSON output
        cat <<EOF
    {
      "success": true,
      "path": "$target_path",
      "relative_path": "$PATH_ARG",
      "mime_type": "$mime_type",
      "encoding": "$detected_encoding",
      "size_bytes": $file_size,
      "total_lines": $total_lines,
      "lines_read": $lines_read,
      "offset": ''${OFFSET:-0},
      "content": $(echo "$content" | jq -Rs .)
    }
    EOF
      else
        # Binary encoding
        if [[ "$detected_encoding" == "base64" ]]; then
          content="$(base64 "$target_path")"
        else
          content="$(xxd -p "$target_path" | tr -d '\n')"
        fi
        
        cat <<EOF
    {
      "success": true,
      "path": "$target_path",
      "relative_path": "$PATH_ARG",
      "mime_type": "$mime_type",
      "encoding": "$detected_encoding",
      "size_bytes": $file_size,
      "content": "$content"
    }
    EOF
      fi
    }

    main
  '';
}
