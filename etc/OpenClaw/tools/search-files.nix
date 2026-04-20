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
    # OpenClaw Tool: search-files
    # Description: Search for files or content in the OpenClaw workspace
    #
    # Usage: search-files <pattern> [--path=DIR] [--type=TYPE] [--max-results=N]
    #
    # Arguments:
    #   pattern          - Search pattern (regex supported)
    #   --path=DIR       - Directory to search (default: workspace)
    #   --type=TYPE      - File type: file, dir, symlink (default: all)
    #   --max-results=N  - Maximum results (default: 100)
    #   --content        - Search file contents instead of names
    #   --case-sensitive - Case-sensitive search
    #
    # Output:
    #   JSON array of matching files or content lines
    #
    # Examples:
    #   search-files "\.txt$"
    #   search-files "error" --content --path=logs
    #   search-files "TODO" --content --max-results=50

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    MAX_RESULTS=100

    # Parse arguments
    PATTERN=""
    SEARCH_PATH=""
    FILE_TYPE=""
    MAX_RESULTS_ARG=$MAX_RESULTS
    CONTENT_SEARCH=false
    CASE_SENSITIVE=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --path=*)
          SEARCH_PATH="''${1#*=}"
          shift
          ;;
        --type=*)
          FILE_TYPE="''${1#*=}"
          shift
          ;;
        --max-results=*)
          MAX_RESULTS_ARG="''${1#*=}"
          shift
          ;;
        --content|-c)
          CONTENT_SEARCH=true
          shift
          ;;
        --case-sensitive|-s)
          CASE_SENSITIVE=true
          shift
          ;;
        -*)
          echo "{\"error\": \"Unknown option: $1\"}" >&2
          exit 1
          ;;
        *)
          if [[ -z "$PATTERN" ]]; then
            PATTERN="$1"
          else
            echo "{\"error\": \"Unexpected argument: $1\"}" >&2
            exit 1
          fi
          shift
          ;;
      esac
    done

    if [[ -z "$PATTERN" ]]; then
      echo '{"error": "Missing required argument: pattern"}' >&2
      exit 1
    fi

    # Resolve search path
    if [[ -n "$SEARCH_PATH" ]]; then
      if [[ "$SEARCH_PATH" != /* ]]; then
        SEARCH_PATH="$WORKSPACE/$SEARCH_PATH"
      fi
      # Validate it's within workspace
      local resolved
      resolved="$(readlink -f "$SEARCH_PATH")"
      if [[ ! "$resolved" =~ ^"$WORKSPACE"(/|$) ]]; then
        echo "{\"error\": \"Search path outside workspace\"}" >&2
        exit 2
      fi

      if [[ "$resolved" == "$CONFIG_DIR"* ]]; then
        echo "{\"error\": \"Access denied: AI cannot read system configuration or secrets\"}" >&2
        return 2
      fi

    else
      SEARCH_PATH="$WORKSPACE"
    fi

    # Build search command
    build_search_cmd() {
      local cmd=""
      
      if [[ "$CONTENT_SEARCH" == true ]]; then
        # Content search with ripgrep
        cmd="rg --json"
        
        if [[ "$CASE_SENSITIVE" != true ]]; then
          cmd="$cmd --ignore-case"
        fi

        # Add forced exclusion from .openclaw
        cmd="$cmd --glob '!.openclaw/**'"
        
        cmd="$cmd --max-count=$MAX_RESULTS_ARG"
        cmd="$cmd -- '$PATTERN' '$SEARCH_PATH'"
      else
        # File name search with find + grep
        local type_flag=""
        case "$FILE_TYPE" in
          file) type_flag="-type f" ;;
          dir|directory) type_flag="-type d" ;;
          symlink) type_flag="-type l" ;;
        esac
        
        local grep_opts="-E"
        if [[ "$CASE_SENSITIVE" != true ]]; then
          grep_opts="$grep_opts -i"
        fi
        
        cmd="find '$SEARCH_PATH' -path '$WORKSPACE/.openclaw' -prune -o $type_flag -print 2>/dev/null | grep $grep_opts '$PATTERN' | head -n $MAX_RESULTS_ARG"
      fi
      
      echo "$cmd"
    }

    # Format results as JSON
    format_results() {
      local results=()
      
      if [[ "$CONTENT_SEARCH" == true ]]; then
        # Parse ripgrep JSON output
        while IFS= read -r line && [[ ''${#results[@]} -lt $MAX_RESULTS_ARG ]]; do
          if echo "$line" | jq -e '.type == "match"' >/dev/null 2>&1; then
            local path line_num text
            path=$(echo "$line" | jq -r '.data.path.text')
            line_num=$(echo "$line" | jq -r '.data.line_number')
            text=$(echo "$line" | jq -r '.data.lines.text' | tr -d '\n' | jq -Rs .)
            
            results+=("{\"path\": \"$path\", \"line\": $line_num, \"content\": $text}")
          fi
        done
      else
        # Parse find output
        while IFS= read -r path && [[ ''${#results[@]} -lt $MAX_RESULTS_ARG ]]; do
          [[ -z "$path" ]] && continue
          
          local rel_path type
          rel_path="''${path#$WORKSPACE/}"
          
          if [[ -d "$path" ]]; then
            type="directory"
          elif [[ -L "$path" ]]; then
            type="symlink"
          else
            type="file"
          fi
          
          results+=("{\"path\": \"$path\", \"relative_path\": \"$rel_path\", \"type\": \"$type\"}")
        done
      fi
      
      echo "''${results[@]}"
    }

    # Main logic
    main() {
      if [[ ! -d "$SEARCH_PATH" ]]; then
        echo "{\"error\": \"Search path does not exist: $SEARCH_PATH\"}" >&2
        exit 1
      fi
      
      local search_cmd
      search_cmd="$(build_search_cmd)"
      
      local results
      results=$(eval "$search_cmd" 2>/dev/null | head -n $((MAX_RESULTS_ARG * 2)))
      
      local formatted
      formatted=$(echo "$results" | format_results)
      
      local count=0
      if [[ -n "$formatted" ]]; then
        count=$(echo "$formatted" | wc -w)
      fi
      
      echo "{"
      echo "  \"success\": true,"
      echo "  \"pattern\": \"$PATTERN\","
      echo "  \"search_path\": \"$SEARCH_PATH\","
      echo "  \"search_type\": $(if [[ "$CONTENT_SEARCH" == true ]]; then echo '"content"'; else echo '"filename"'; fi),"
      echo "  \"results_count\": $count,"
      echo "  \"max_results\": $MAX_RESULTS_ARG,"
      echo "  \"results\": ["
      
      if [[ -n "$formatted" ]]; then
        echo "$formatted" | tr ' ' '\n' | head -n $MAX_RESULTS_ARG | while read -r item; do
          [[ -n "$item" ]] && echo "    $item,"
        done
      fi
      
      echo "  ]"
      echo "}"
    }

    main
  '';
}
