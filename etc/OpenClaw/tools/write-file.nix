# OpenClaw Tool: write-file
#
# Safely writes a file within the OpenClaw workspace.
# Supports text and binary content with various encodings.
# Creates parent directories if needed.

{
  pkgs,
  cfg,
  ...
}:

{
  name = "write-file";
  description = "Create, overwrite, or append to files in the workspace.";
  permissions = "0750";

  usage = "write-file <path> <content> [--append] [--mkdir] [--mode=MODE] [--encoding=ENC]";

  arguments = [
    {
      name = "path";
      desc = "Relative or absolute path to file (required)";
      default = "-";
    }
    {
      name = "content";
      desc = "Text or encoded payload to write (required)";
      default = "-";
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
      desc = "Payload encoding: text, base64, hex";
      default = "text";
    }
  ];

  examples = [
    "write-file my-project/TODO.md \"- [ ] Setup database\\n- [ ] Write API\" --mkdir"
    "write-file my-project/script.sh \"#!/usr/bin/env bash\\necho hi\" --mode=0755"
    "write-file my-project/TODO.md \"- [ ] Setup database\\n- [ ] Write API\" --mkdir"
    "write-file my-project/TODO.md \"- [x] Setup database\\n\" --append"
    "write-file my-project/script.sh \"#!/usr/bin/env bash\\necho hi\" --mode=0755"
  ];

  dependencies = with pkgs; [
    coreutils
    jq
    xxd
  ];

  script = ''
    #!/usr/bin/env bash
    # OpenClaw Tool: write-file
    # Description: Write a file to the OpenClaw workspace
    #
    # Usage: write-file <path> [content|--stdin] [--encoding=ENC] [--append] [--mode=MODE]
    #
    # Arguments:
    #   path           - Relative or absolute path to file (within workspace)
    #   content        - Content to write (or use --stdin)
    #   --encoding=ENC - Content encoding (text, base64, hex)
    #   --append       - Append to file instead of overwriting
    #   --mode=MODE    - File permissions (default: 0644)
    #   --mkdir        - Create parent directories if needed
    #
    # Output:
    #   JSON object with result or error
    #
    # Examples:
    #   write-file workspace/hello.txt "Hello, World!"
    #   write-file workspace/data.json '{"key": "value"}'
    #   write-file workspace/binary.bin "SGVsbG8=" --encoding=base64
    #   echo "content" | write-file workspace/file.txt --stdin
    #
    # Exit codes:
    #   0 - Success
    #   1 - Invalid input
    #   2 - Permission denied or outside workspace

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"

    CONFIG_DIR="$WORKSPACE/.openclaw"
    MAX_FILE_SIZE=$((10 * 1024 * 1024))  # 10MB max

    # Parse arguments
    PATH_ARG=""
    CONTENT=""
    ENCODING="text"
    APPEND=false
    MODE="0644"
    USE_STDIN=false
    MKDIR=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --stdin)
          USE_STDIN=true
          shift
          ;;
        --encoding=*)
          ENCODING="''${1#*=}"
          shift
          ;;
        --append)
          APPEND=true
          shift
          ;;
        --mode=*)
          MODE="''${1#*=}"
          shift
          ;;
        --mkdir)
          MKDIR=true
          shift
          ;;
        -*)
          echo "{\"error\": \"Unknown option: $1\"}" >&2
          exit 1
          ;;
        *)
          if [[ -z "$PATH_ARG" ]]; then
            PATH_ARG="$1"
            shift
          elif [[ -z "$CONTENT" ]]; then
            CONTENT="$1"
            shift
          else
            echo "{\"error\": \"Unexpected argument: $1\"}" >&2
            exit 1
          fi
          ;;
      esac
    done

    if [[ -z "$PATH_ARG" ]]; then
      echo '{"error": "Missing required argument: path"}' >&2
      exit 1
    fi

    if [[ "$USE_STDIN" == true ]]; then
      CONTENT="$(cat)"
    elif [[ -z "$CONTENT" ]]; then
      echo '{"error": "Missing required argument: content (or use --stdin)"}' >&2
      exit 1
    fi

    # Secure Path Resolution
    resolve_path() {
      local input_path="$1"
      
      # Handle relative paths
      if [[ "$input_path" != /* ]]; then
        input_path="$WORKSPACE/$input_path"
      fi
      
      # Use realpath -m to securely resolve traversals without needing the file to exist
      local resolved
      resolved="$(realpath -m "$input_path")"
      
      # 1. Validate it's within workspace
      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "{\"error\": \"Access denied: path outside workspace\"}" >&2
        return 2
      fi

      # 2. CRITICAL: Validate it is NOT trying to write to .openclaw
      if [[ "$resolved" == "$CONFIG_DIR"* ]]; then
        echo "{\"error\": \"Access denied: AI cannot modify OpenClaw configuration files\"}" >&2
        return 2
      fi
      
      echo "$resolved"
    }

    # Main logic
    main() {
      local target_path parent_dir

      target_path="$(resolve_path "$PATH_ARG")" || exit 2

      parent_dir="$(dirname "$target_path")"

      # Create parent directories if needed
      if [[ ! -d "$parent_dir" ]]; then
        if [[ "$MKDIR" == true ]]; then
          mkdir -p "$parent_dir"
        else
          echo "{\"error\": \"Parent directory does not exist: $parent_dir (use --mkdir to create)\"}" >&2
          exit 1
        fi
      fi
      
      # Check size limit
      local content_size
      content_size="$(printf '%s' "$CONTENT" | wc -c)"
      
      if [[ $content_size -gt $MAX_FILE_SIZE ]]; then
        echo "{\"error\": \"Content too large: $content_size bytes (max $MAX_FILE_SIZE)\"}" >&2
        exit 1
      fi
      
      # Decode and write content
      local write_op="created"
      if [[ -f "$target_path" ]]; then
        if [[ "$APPEND" == true ]]; then
          write_op="appended"
        else
          write_op="overwritten"
        fi
      fi
      
      case "$ENCODING" in
        text|utf-8)
          if [[ "$APPEND" == true ]]; then
            printf '%s\n' "$CONTENT" >> "$target_path"
          else
            printf '%s\n' "$CONTENT" > "$target_path"
          fi
          ;;
        base64)
          if [[ "$APPEND" == true ]]; then
            printf '%s' "$CONTENT" | base64 -d >> "$target_path"
          else
            printf '%s' "$CONTENT" | base64 -d > "$target_path"
          fi
          ;;
        hex)
          if [[ "$APPEND" == true ]]; then
            printf '%s' "$CONTENT" | xxd -r -p >> "$target_path"
          else
            printf '%s' "$CONTENT" | xxd -r -p > "$target_path"
          fi
          ;;
        *)
          echo "{\"error\": \"Unknown encoding: $ENCODING\"}" >&2
          exit 1
          ;;
      esac
      
      # Set file permissions
      chmod "$MODE" "$target_path"
      
      # Get final file info
      local final_size final_mode
      final_size="$(stat -c%s "$target_path")"
      final_mode="$(stat -c%a "$target_path")"
      
      cat <<EOF
    {
      "success": true,
      "path": "$target_path",
      "relative_path": "$PATH_ARG",
      "operation": "$write_op",
      "encoding": "$ENCODING",
      "size_bytes": $final_size,
      "mode": "$final_mode"
    }
    EOF
    }

    main
  '';
}
