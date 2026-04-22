# OpenClaw Tool: search-files
#
# Searches for files or content within the OpenClaw workspace.
# Uses ripgrep for fast, efficient searching.

{
  pkgs,
  cfg,
  ...
}:

{
  name = "search-files";
  description = "Search for files or content in the OpenClaw workspace";
  permissions = "0750";

  usage = "search-files <pattern> [--path=DIR] [--type=TYPE] [--max-results=N] [--content|-c] [--case-sensitive|-s]";

  arguments = [
    {
      name = "pattern";
      desc = "Search pattern (regex supported)";
      default = "required";
    }
    {
      name = "--path";
      desc = "Directory to search";
      default = "workspace root";
    }
    {
      name = "--type";
      desc = "Filter by type: file, dir, symlink";
      default = "all";
    }
    {
      name = "--max-results";
      desc = "Maximum results to return";
      default = "100";
    }
    {
      name = "--content";
      desc = "Search inside file contents instead of filenames";
      default = "false";
    }
    {
      name = "--case-sensitive";
      desc = "Enforce case matching";
      default = "false";
    }
  ];

  examples = [
    "search-files \"\\.txt$\""
    "search-files \"error\" --content --path=logs"
    "search-files \"TODO\" --content --max-results=50"
  ];

  dependencies = with pkgs; [
    coreutils
    ripgrep
    jq
  ];

  script = ''
    #!/usr/bin/env bash
    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"
    MAX_RESULTS=100

    PATTERN=""
    SEARCH_PATH=""
    FILE_TYPE=""
    MAX_RESULTS_ARG=$MAX_RESULTS
    CONTENT_SEARCH=false
    CASE_SENSITIVE=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --path=*) SEARCH_PATH="''${1#*=}" ;;
        --type=*) FILE_TYPE="''${1#*=}" ;;
        --max-results=*) MAX_RESULTS_ARG="''${1#*=}" ;;
        --content|-c) CONTENT_SEARCH=true ;;
        --case-sensitive|-s) CASE_SENSITIVE=true ;;
        -*) echo '{"error":"Unknown option"}' >&2; exit 1 ;;
        *)
          [[ -z "$PATTERN" ]] && PATTERN="$1" || { echo '{"error":"Unexpected argument"}' >&2; exit 1; }
          ;;
      esac
      shift
    done

    [[ -z "$PATTERN" ]] && { echo '{"error":"Missing pattern"}' >&2; exit 1; }

    # Resolve path
    SEARCH_PATH="''${SEARCH_PATH:-$WORKSPACE}"
    [[ "$SEARCH_PATH" != /* ]] && SEARCH_PATH="$WORKSPACE/$SEARCH_PATH"

    RESOLVED="$(readlink -f "$SEARCH_PATH")"

    if [[ ! "$RESOLVED" =~ ^"$WORKSPACE"(/|$) ]]; then
      echo '{"error":"Path outside workspace"}' >&2
      exit 2
    fi

    if [[ "$RESOLVED" == "$CONFIG_DIR"* ]]; then
      echo '{"error":"Access denied"}' >&2
      exit 2
    fi

    [[ ! -d "$RESOLVED" ]] && { echo '{"error":"Path not found"}' >&2; exit 1; }

    RESULTS_JSON="[]"

    if [[ "$CONTENT_SEARCH" == true ]]; then
      RG_ARGS=(--json --max-count "$MAX_RESULTS_ARG" --glob '!.openclaw/**')
      [[ "$CASE_SENSITIVE" != true ]] && RG_ARGS+=(--ignore-case)

      while IFS= read -r line; do
        if echo "$line" | jq -e '.type=="match"' >/dev/null; then
          path=$(echo "$line" | jq -r '.data.path.text')
          line_num=$(echo "$line" | jq -r '.data.line_number')
          text=$(echo "$line" | jq -r '.data.lines.text')

          RESULTS_JSON=$(echo "$RESULTS_JSON" | jq \
            --arg p "$path" \
            --arg t "$text" \
            --argjson l "$line_num" \
            '. += [{"path":$p,"line":$l,"content":$t}]')
        fi
      done < <(rg "''${RG_ARGS[@]}" -- "$PATTERN" "$RESOLVED")

    else
      FIND_ARGS=("$RESOLVED" -path "$CONFIG_DIR" -prune -o)

      case "$FILE_TYPE" in
        file) FIND_ARGS+=(-type f) ;;
        dir|directory) FIND_ARGS+=(-type d) ;;
        symlink) FIND_ARGS+=(-type l) ;;
      esac

      FIND_ARGS+=(-print)

      while IFS= read -r path; do
        rel="''${path#$WORKSPACE/}"

        if [[ -d "$path" ]]; then type="directory"
        elif [[ -L "$path" ]]; then type="symlink"
        else type="file"
        fi

        RESULTS_JSON=$(echo "$RESULTS_JSON" | jq \
          --arg p "$path" \
          --arg r "$rel" \
          --arg t "$type" \
          '. += [{"path":$p,"relative_path":$r,"type":$t}]')

      done < <(find "''${FIND_ARGS[@]}" 2>/dev/null | grep -E ''${CASE_SENSITIVE:+} ''${CASE_SENSITIVE:--i} "$PATTERN" | head -n "$MAX_RESULTS_ARG")
    fi

    COUNT=$(echo "$RESULTS_JSON" | jq 'length')

    jq -n \
      --arg pattern "$PATTERN" \
      --arg path "$RESOLVED" \
      --arg type "$( [[ "$CONTENT_SEARCH" == true ]] && echo content || echo filename )" \
      --argjson count "$COUNT" \
      --argjson max "$MAX_RESULTS_ARG" \
      --argjson results "$RESULTS_JSON" \
      '{
        success: true,
        pattern: $pattern,
        search_path: $path,
        search_type: $type,
        results_count: $count,
        max_results: $max,
        results: $results
      }'
  '';
}
