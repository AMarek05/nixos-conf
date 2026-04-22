{
  pkgs,
  cfg,
  config,
  ...
}:

{
  name = "gh";
  permissions = "0750";

  description = "GitHub CLI wrapper: pr create, issue create, issue list, pr list";

  usage = "gh <pr-create|pr-list|issue-create|issue-list> [args...]";

  arguments = [
    {
      name = "operation";
      desc = "Operation: pr-create, pr-list, issue-create, issue-list";
      default = "required";
    }
    {
      name = "title";
      desc = "Title for PR or issue";
      default = "\"\"";
    }
    {
      name = "body";
      desc = "Body/description for PR or issue";
      default = "\"\"";
    }
    {
      name = "--repo";
      desc = "Repository in format owner/repo";
      default = "current repo";
    }
    {
      name = "--base";
      desc = "Base branch for PR";
      default = "main";
    }
    {
      name = "--head";
      desc = "Head branch for PR (when not on the branch)";
      default = "\"\"";
    }
    {
      name = "--limit";
      desc = "Number of items to list";
      default = "10";
    }
  ];

  examples = [
    "gh pr-create \"Add new feature\" \"Implements feature X\" --repo owner/repo --base main"
    "gh pr-create \"Fix bug\" \"Fixes issue\" --head feature-branch"
    "gh issue-create \"Bug: something broken\" \"Description of the bug\" --repo owner/repo"
    "gh issue-list --repo owner/repo --limit 20"
    "gh pr-list --repo owner/repo --limit 10"
  ];

  dependencies = with pkgs; [
    gnugrep
    gnused
    gh
    jq
    coreutils
  ];

  script = '
    #!/usr/bin/env bash
    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"

    fail() {
      local msg="${1:-}"
      local code="${2:-1}"
      jq -n --arg error "$msg" --argjson code "$code" '{success: false, exit_code: $code, error: $error}'
      exit "$code"
    }

    get_gh_token() {
      local tok=""
      if [[ -f "${config.sops.secrets."gh-token".path}" ]]; then
        tok=$(cat "${config.sops.secrets."gh-token".path}")
      fi
      echo "$tok"
    }

    configure_gh() {
      local token
      token=$(get_gh_token)
      if [[ -n "$token" ]]; then
        if ! gh auth status &>/dev/null; then
          echo "$token" | gh auth login --with-token 2>/dev/null || true
        fi
      fi
    }

    extract_repo_from_git_remote() {
      local remote_url="${1:-}"
      # Use bash pattern matching instead of sed
      if [[ "$remote_url" =~ github\.com[:/](.*)\.git$ ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ "$remote_url" =~ github\.com[:/](.*)$ ]]; then
        echo "${BASH_REMATCH[1]}"
      fi
    }

    extract_url() {
      local result="${1:-}"
      # bash pattern: everything starting with https://github.com/
      if [[ "$result" =~ https://github\.com/[^[:space:]]* ]]; then
        echo "${BASH_REMATCH[0]}"
      fi
    }

    OP="${1:-}"
    [[ -z $OP ]] && fail "Usage: gh <pr-create|pr-list|issue-create|issue-list> [args]" 1

    configure_gh

    case $OP in
      pr-create)
        TITLE=""
        BODY=""
        REPO=""
        BASE="main"
        HEAD_BRANCH=""

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo=*) REPO="${1#*=}" ;;
            --base=*) BASE="${1#*=}" ;;
            --head=*) HEAD_BRANCH="${1#*=}" ;;
            --title=*) TITLE="${1#*=}" ;;
            --body=*) BODY="${1#*=}" ;;
            *)
              if [[ -z "$TITLE" ]]; then
                TITLE="$1"
              else
                [[ -n "$BODY" ]] && BODY="$BODY"$'\n'"$1" || BODY="$1"
              fi
              ;;
          esac
          shift
        done

        if [[ -z "$REPO" ]]; then
          local remote_url
          remote_url=$(git remote get-url origin 2>/dev/null || echo "")
          REPO=$(extract_repo_from_git_remote "$remote_url")
        fi

        [[ -z "$TITLE" ]] && fail "pr-create requires a title" 1

        EXIT_CODE=0
        RESULT=""

        local gh_cmd_args=()
        [[ -n "$REPO" ]] && gh_cmd_args+=(--repo "$REPO")
        gh_cmd_args+=(--title "$TITLE" --body "$BODY" --base "$BASE")
        [[ -n "$HEAD_BRANCH" ]] && gh_cmd_args+=(--head "$HEAD_BRANCH")

        RESULT=$(gh pr create "${gh_cmd_args[@]}" 2>&1) || EXIT_CODE=$?

        if [[ $EXIT_CODE -eq 0 ]]; then
          local pr_url
          pr_url=$(extract_url "$RESULT")
          jq -n --arg op "pr-create" --arg title "$TITLE" --arg repo "$REPO" --arg base "$BASE" \
            --arg url "$pr_url" --argjson code "$EXIT_CODE" \
            '{success: true, operation: $op, title: $title, repo: $repo, base: $base, url: $url, exit_code: $code}'
        else
          jq -n --arg op "pr-create" --arg title "$TITLE" --arg repo "$REPO" \
            --argjson code "$EXIT_CODE" --arg error "$RESULT" \
            '{success: false, operation: $op, title: $title, repo: $repo, exit_code: $code, error: $error}'
        fi
        ;;

      pr-list)
        REPO=""
        LIMIT="10"
        STATE="open"

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo=*) REPO="${1#*=}" ;;
            --limit=*) LIMIT="${1#*=}" ;;
            --state=*) STATE="${1#*=}" ;;
          esac
          shift
        done

        if [[ -z "$REPO" ]]; then
          local remote_url
          remote_url=$(git remote get-url origin 2>/dev/null || echo "")
          REPO=$(extract_repo_from_git_remote "$remote_url")
        fi

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh pr list --repo "$REPO" --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh pr list --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          printf "%s\n" "$RESULT" | jq -c '{success: true, operation: "pr-list", repo: "", count: (. | length), prs: .}'
        else
          jq -n --arg op "pr-list" --arg repo "$REPO" --argjson code "$EXIT_CODE" \
            --arg error "$RESULT" \
            '{success: false, operation: $op, repo: $repo, exit_code: $code, error: $error}'
        fi
        ;;

      issue-create)
        TITLE=""
        BODY=""
        REPO=""

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo=*) REPO="${1#*=}" ;;
            --title=*) TITLE="${1#*=}" ;;
            --body=*) BODY="${1#*=}" ;;
            *)
              if [[ -z "$TITLE" ]]; then
                TITLE="$1"
              else
                [[ -n "$BODY" ]] && BODY="$BODY"$'\n'"$1" || BODY="$1"
              fi
              ;;
          esac
          shift
        done

        if [[ -z "$REPO" ]]; then
          local remote_url
          remote_url=$(git remote get-url origin 2>/dev/null || echo "")
          REPO=$(extract_repo_from_git_remote "$remote_url")
        fi

        [[ -z "$TITLE" ]] && fail "issue-create requires a title" 1

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh issue create --title "$TITLE" --body "$BODY" 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          local issue_url
          issue_url=$(extract_url "$RESULT")
          local issue_num=""
          if [[ "$RESULT" =~ [0-9]+$ ]]; then
            issue_num="${BASH_REMATCH[0]}"
          fi
          jq -n --arg op "issue-create" --arg title "$TITLE" --arg repo "$REPO" \
            --arg url "$issue_url" --arg number "${issue_num:-0}" --argjson code "$EXIT_CODE" \
            '{success: true, operation: $op, title: $title, repo: $repo, number: $number, url: $url, exit_code: $code}'
        else
          jq -n --arg op "issue-create" --arg title "$TITLE" --arg repo "$REPO" \
            --argjson code "$EXIT_CODE" --arg error "$RESULT" \
            '{success: false, operation: $op, title: $title, repo: $repo, exit_code: $code, error: $error}'
        fi
        ;;

      issue-list)
        REPO=""
        LIMIT="10"
        STATE="open"

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo=*) REPO="${1#*=}" ;;
            --limit=*) LIMIT="${1#*=}" ;;
            --state=*) STATE="${1#*=}" ;;
          esac
          shift
        done

        if [[ -z "$REPO" ]]; then
          local remote_url
          remote_url=$(git remote get-url origin 2>/dev/null || echo "")
          REPO=$(extract_repo_from_git_remote "$remote_url")
        fi

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh issue list --repo "$REPO" --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh issue list --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          printf "%s\n" "$RESULT" | jq -c '{success: true, operation: "issue-list", repo: "", count: (. | length), issues: .}'
        else
          jq -n --arg op "issue-list" --arg repo "$REPO" --argjson code "$EXIT_CODE" \
            --arg error "$RESULT" \
            '{success: false, operation: $op, repo: $repo, exit_code: $code, error: $error}'
        fi
        ;;

      *)
        fail "Unknown operation: $OP. Use pr-create, pr-list, issue-create, or issue-list" 1 ;;
    esac
  ';
}
