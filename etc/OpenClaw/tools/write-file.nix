# OpenClaw Tool: write-file (FIXED)
# Bugfix: stdin streaming now preserves newlines correctly.
# Key fix: USE_STDIN mode streams via tee, never captures to shell variable.
{
  pkgs,
  cfg,
  ...
}:

{
  name = "write-file";
  description = "Create, overwrite, or append to files in the workspace.";
  permissions = "0750";

  usage = "write-file <path> [content|--stdin] [--append] [--mkdir] [--mode=MODE] [--encoding=ENC]";

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
    {
      name = "--stdin";
      desc = "Read content from stdin instead of argument";
      default = "false";
    }
  ];

  examples = [
    "write-file my-project/TODO.md \"# TODO\\n- item\" --mkdir"
    "echo \"content\" | write-file my-project/file.txt --stdin"
    "base64_data | write-file my-project/image.png --encoding=base64"
  ];

  dependencies = with pkgs; [
    coreutils
    jq
    xxd
  ];

  script = ''
    #!/usr/bin/env bash
    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"
    MAX_FILE_SIZE=$((10*1024*1024))

    PATH_ARG=""
    CONTENT=""
    ENCODING="text"
    APPEND=false
    MODE="0644"
    MKDIR=false
    USE_STDIN=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --stdin) USE_STDIN=true; shift ;;
        --encoding=*) ENCODING="''${1#*=}"; shift ;;
        --append) APPEND=true; shift ;;
        --mode=*) MODE="''${1#*=}"; shift ;;
        --mkdir) MKDIR=true; shift ;;
        -*) echo "{\"error\": \"Unknown option: $1\"}" >&2; exit 1 ;;
        *)
          if [[ -z "$PATH_ARG" ]]; then PATH_ARG="$1"; shift
          elif [[ -z "$CONTENT" ]]; then CONTENT="$1"; shift
          else echo "{\"error\": \"Unexpected argument: $1\"}" >&2; exit 1; fi ;;
      esac
    done

    [[ -z "$PATH_ARG" ]] && echo "{\"error\": \"Missing required argument: path\"}" >&2 && exit 1

    if [[ "$USE_STDIN" == true ]]; then
      CONTENT=""
    elif [[ -z "$CONTENT" ]]; then
      echo "{\"error\": \"Missing required argument: content (or use --stdin)\"}" >&2 && exit 1
    fi

    resolve_path() {
      local p="$1"
      [[ "$p" != /* ]] && p="$WORKSPACE/$p"
      p="$(realpath -m "$p")"
      [[ "$p" =~ ^"$WORKSPACE"(/|$) ]] || { echo "{\"error\": \"Access denied: path outside workspace\"}" >&2; return 2; }
      [[ "$p" == "$CONFIG_DIR"* ]] && { echo "{\"error\": \"Access denied: cannot modify OpenClaw configuration\"}" >&2; return 2; }
      echo "$p"
    }

    target_path="$(resolve_path "$PATH_ARG")" || exit 2
    parent_dir="$(dirname "$target_path")"

    if [[ ! -d "$parent_dir" ]]; then
      if [[ "$MKDIR" == true ]]; then mkdir -p "$parent_dir"
      else echo "{\"error\": \"Parent directory does not exist (use --mkdir)\"}" >&2; exit 1; fi
    fi

    TEMP=$(mktemp)
    trap 'rm -f "$TEMP"' EXIT

    # Handle payload stream and decode depending on mode
    if [[ "$USE_STDIN" == true ]]; then
      case "$ENCODING" in
        text|utf-8) bytes=$(cat | tee "$TEMP" | wc -c) ;;
        base64) bytes=$(base64 -d | tee "$TEMP" | wc -c) ;;
        hex) bytes=$(xxd -r -p | tee "$TEMP" | wc -c) ;;
        *) echo "{\"error\": \"Unknown encoding: $ENCODING\"}" >&2; exit 1 ;;
      esac
    else
      case "$ENCODING" in
        text|utf-8) printf "%s" "$CONTENT" > "$TEMP" ;;
        base64) printf "%s" "$CONTENT" | base64 -d > "$TEMP" ;;
        hex) printf "%s" "$CONTENT" | xxd -r -p > "$TEMP" ;;
        *) echo "{\"error\": \"Unknown encoding: $ENCODING\"}" >&2; exit 1 ;;
      esac
      bytes=$(wc -c < "$TEMP")
    fi

    [[ $bytes -gt $MAX_FILE_SIZE ]] && echo "{\"error\": \"Content too large: $bytes bytes\"}" >&2 && exit 1

    write_op="created"
    [[ -f "$target_path" ]] && [[ "$APPEND" == true ]] && write_op="appended" || write_op="overwritten"

    if [[ "$APPEND" == true ]]; then
      cat "$TEMP" >> "$target_path"
    else
      cat "$TEMP" > "$target_path"
    fi

    chmod "$MODE" "$target_path"

    cat <<JSON
    {"success": true, "path": "$target_path", "relative_path": "$PATH_ARG", "operation": "$write_op", "encoding": "$ENCODING", "size_bytes": $(stat -c%s "$target_path"), "mode": "$(stat -c%a "$target_path")"}
    JSON
  '';
}
