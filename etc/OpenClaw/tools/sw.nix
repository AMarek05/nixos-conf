{ pkgs, cfg, ... }:

{
  name = "sw";
  description = "Smart write: stream stdin to workspace file. Fixes newline/binary bugs in write-file.";
  permissions = "0750";

  usage = "sw <path> [--append] [--mkdir] [--mode=MODE] [--encoding=ENC]";

  arguments = [
    {
      name = "path";
      desc = "Relative or absolute path (required)";
      default = "required";
    }
    {
      name = "--append";
      desc = "Append instead of overwrite";
      default = "false";
    }
    {
      name = "--mkdir";
      desc = "Create parent directories";
      default = "false";
    }
    {
      name = "--mode";
      desc = "Octal permissions (e.g. 0755)";
      default = "0644";
    }
    {
      name = "--encoding";
      desc = "text (default), base64, hex";
      default = "text";
    }
  ];

  examples = [
    "printf \"line1\\nline2\\n\" | sw test.txt"
    "base64_data | sw data.bin --encoding=base64"
    "sw log.txt --append < new.txt"
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
    MAX_SIZE=$((10*1024*1024))
    PATH_ARG=""
    APPEND=false
    MKDIR=false
    MODE="0644"
    ENCODING="text"

    while [[ $# -gt 0 ]]; do
      case $1 in
        --append) APPEND=true; shift ;;
        --mkdir) MKDIR=true; shift ;;
        --mode=*) MODE="''${1#*=}"; shift ;;
        --encoding=*) ENCODING="''${1#*=}"; shift ;;
        -*) echo "{\"error\": \"Unknown: $1\"}" >&2; exit 1 ;;
        *) [[ -z $PATH_ARG ]] && PATH_ARG=$1 || { echo "{\"error\": \"Extra: $1\"}" >&2; exit 1; }; shift ;;
      esac
    done

    [[ -z $PATH_ARG ]] && echo "{\"error\": \"No path\"}" >&2 && exit 1

    resolve_path() {
      local p=$1
      [[ $p != /* ]] && p=$WORKSPACE/$p
      p=$(realpath -m "$p")
      [[ $p =~ ^$WORKSPACE(/|$) ]] || { echo "{\"error\": \"Outside workspace\"}" >&2; return 2; }
      [[ $p == $CONFIG_DIR* ]] && { echo "{\"error\": \"openclaw config blocked\"}" >&2; return 2; }
      echo "$p"
    }

    target=$(resolve_path "$PATH_ARG") || exit 2
    parent=$(dirname "$target")
    [[ ! -d $parent ]] && { [[ $MKDIR == true ]] && mkdir -p "$parent" || { echo "{\"error\": \"No dir: $parent (use --mkdir)\"}" >&2; exit 1; }; }

    TEMP=$(mktemp); trap "rm -f $TEMP" EXIT
    case $ENCODING in
      text|utf-8) bytes=$(cat | tee $TEMP | wc -c) ;;
      base64) bytes=$(base64 -d | tee $TEMP | wc -c) ;;
      hex) bytes=$(xxd -r -p | tee $TEMP | wc -c) ;;
      *) echo "{\"error\": \"Bad encoding: $ENCODING\"}" >&2; exit 1 ;;
    esac

    [[ $bytes -gt $MAX_SIZE ]] && echo "{\"error\": \"Too large: $bytes\"}" >&2 && exit 1

    op="created"
    [[ -f $target ]] && [[ $APPEND == true ]] && op="appended" || op="overwritten"
    [[ $APPEND == true ]] && cat $TEMP >> $target || cat $TEMP > $target
    chmod $MODE $target

    cat <<OUT
    {"success": true, "path": "$target", "relative_path": "$PATH_ARG", "operation": "$op", "encoding": "$ENCODING", "size_bytes": $(stat -c%s $target), "mode": "$(stat -c%a $target)"}
    OUT
  '';
}
