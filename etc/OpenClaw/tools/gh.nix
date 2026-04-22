# OpenClaw Tool: gh
# Description: GitHub CLI wrapper for creating PRs, issues, and listing them.
# Supports: pr create, issue create, issue list, pr list.

{
  pkgs,
  cfg,
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
      name = "--limit";
      desc = "Number of items to list";
      default = "10";
    }
  ];

  examples = [
    "gh pr-create \"Add new feature\" \"Implements feature X\" --repo owner/repo --base main"
    "gh issue-create \"Bug: something broken\" \"Description of the bug\" --repo owner/repo"
    "gh issue-list --repo owner/repo --limit 20"
    "gh pr-list --repo owner/repo --limit 10"
  ];

  dependencies = with pkgs; [
    gh
    jq
    coreutils
  ];

  script = '
    #!/usr/bin/env bash
    # OpenClaw Tool: gh
    # Description: GitHub CLI wrapper for PR and issue operations
    # Status: REVIEWED

    set -euo pipefail

    WORKSPACE="${cfg.workspace}"
    CONFIG_DIR="$WORKSPACE/.openclaw"
    CREDS_DIR="$WORKSPACE/.openclaw/credentials"

    fail() {
      jq -n --arg error "$1" --argjson code "${2:-1}" \
        '{success: false, exit_code: $code, error: $error}'
      exit "${2:-1}"
    }

    # Get GitHub token from credentials
    get_gh_token() {
      local tok=""
      [[ -f "$CREDS_DIR/github-token" ]] && tok=$(cat "$CREDS_DIR/github-token")
      echo "$tok"
    }

    # Configure gh auth if token exists
    configure_gh() {
      local token
      token=$(get_gh_token)
      if [[ -n "$token" ]]; then
        # Check if already authenticated
        if ! gh auth status &>/dev/null; then
          echo "$token" | gh auth login --with-token 2>/dev/null || true
        fi
      fi
    }

    OP="${1:-}"
    [[ -z $OP ]] && fail "Usage: gh <pr-create|pr-list|issue-create|issue-list> [args...]" 1

    configure_gh

    case $OP in
      pr-create)
        TITLE=""
        BODY=""
        REPO=""
        BASE="main"
        FILES=""

        # Parse args
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo=*) REPO="${1#*=}" ;;
            --base=*) BASE="${1#*=}" ;;
            --title=*) TITLE="${1#*=}" ;;
            --body=*) BODY="${1#*=}" ;;
            --file=*) FILES="$FILES --repo ${1#*=}" ;;
            *)
              [[ -z "$TITLE" ]] && TITLE="$1"
              [[ -n "$BODY" ]] && BODY="$BODY\n$1"
              ;;
          esac
          shift
        done

        [[ -z "$REPO" ]] && REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "")

        if [[ -z "$TITLE" ]]; then
          fail "pr-create requires a title. Usage: gh pr-create <title> [--repo owner/repo] [--base branch]" 1
        fi

        EXIT_CODE=0
        RESULT=""

        if [[ -n "$REPO" ]]; then
          RESULT=$(gh pr create --repo "$REPO" --title "$TITLE" --body "$BODY" --base "$BASE" 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh pr create --title "$TITLE" --body "$BODY" --base "$BASE" 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          PR_URL=$(echo "$RESULT" | grep -o "https://github.com/[^ ]*" | head -1)
          jq -n --arg op "pr-create" --arg title "$TITLE" --arg repo "$REPO" --arg base "$BASE" \
            --arg url "$PR_URL" --argjson code "$EXIT_CODE" \
            '{success: true, operation: $op, title: $title, repo: $repo, base: $base, url: $url, exit_code: $code, output: $output}'
        else
          jq -n --arg op "pr-create" --arg title "$TITLE" --arg repo "$REPO" \
            --argjson code "${EXIT_CODE}" --argjson error "$(printf "%s" "$RESULT" | jq -Rs .)" \
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
            *) ;;
          esac
          shift
        done

        [[ -z "$REPO" ]] && REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "")

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh pr list --repo "$REPO" --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh pr list --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          echo "$RESULT" | jq -c '{success: true, operation: "pr-list", repo: "", count: (. | length), prs: .}'
        else
          jq -n --arg op "pr-list" --arg repo "$REPO" --argjson code "${EXIT_CODE}" \
            --argjson error "$(printf "%s" "$RESULT" | jq -Rs .)" \
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
              [[ -z "$TITLE" ]] && TITLE="$1"
              [[ -n "$BODY" ]] && BODY="$BODY\n$1"
              ;;
          esac
          shift
        done

        [[ -z "$REPO" ]] && REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "")

        if [[ -z "$TITLE" ]]; then
          fail "issue-create requires a title. Usage: gh issue-create <title> [--repo owner/repo] [--body body-text]" 1
        fi

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh issue create --title "$TITLE" --body "$BODY" 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          ISSUE_URL=$(echo "$RESULT" | grep -o "https://github.com/[^ ]*" | head -1)
          ISSUE_NUM=$(echo "$RESULT" | grep -o "[0-9]*$")
          jq -n --arg op "issue-create" --arg title "$TITLE" --arg repo "$REPO" \
            --arg url "$ISSUE_URL" --arg number "${ISSUE_NUM:-0}" --argjson code "${EXIT_CODE}" \
            '{success: true, operation: $op, title: $title, repo: $repo, number: $number, url: $url, exit_code: $code, output: $output}'
        else
          jq -n --arg op "issue-create" --arg title "$TITLE" --arg repo "$REPO" \
            --argjson code "${EXIT_CODE}" --argjson error "$(printf "%s" "$RESULT" | jq -Rs .)" \
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

        [[ -z "$REPO" ]] && REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "")

        EXIT_CODE=0
        RESULT=""
        if [[ -n "$REPO" ]]; then
          RESULT=$(gh issue list --repo "$REPO" --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        else
          RESULT=$(gh issue list --limit "$LIMIT" --state "$STATE" --json number,title,state,url,author,createdAt 2>&1) || EXIT_CODE=$?
        fi

        if [[ $EXIT_CODE -eq 0 ]]; then
          echo "$RESULT" | jq -c '{success: true, operation: "issue-list", repo: "", count: (. | length), issues: .}'
        else
          jq -n --arg op "issue-list" --arg repo "$REPO" --argjson code "${EXIT_CODE}" \
            --argjson error "$(printf "%s" "$RESULT" | jq -Rs .)" \
            '{success: false, operation: $op, repo: $repo, exit_code: $code, error: $error}'
        fi
        ;;

      *)
        fail "Unknown operation: $OP. Use pr-create, pr-list, issue-create, or issue-list" 1
        ;;
    esac
  ';
}
