#!/usr/bin/env bash
set -euo pipefail

# --- Helper Functions ---
fail() {
  local msg="${1:-}"
  local code="${2:-1}"
  jq -n --arg error "$msg" --argjson code "$code" '{success: false, exit_code: $code, error: $error}'
  exit "$code"
}

extract_repo_from_git_remote() {
  local remote_url="${1:-}"
  if [[ "$remote_url" =~ github\.com[:/]([^ ]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]%.git}"
  fi
}

get_repo() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || true)
    repo=$(extract_repo_from_git_remote "$remote_url")
  fi
  echo "$repo"
}

extract_url() {
  local result="${1:-}"
  if [[ "$result" =~ https://github\.com/[^[:space:]]* ]]; then
    echo "${BASH_REMATCH[0]}"
  fi
}

# --- Main Initialization ---
OP="${1:-}"
[[ -z "$OP" ]] && fail "Usage: gh <pr-create|pr-list|issue-create|issue-list> [args]" 1
shift

REPO=""
TITLE=""
BODY=""
LIMIT="10"
STATE="open"
BASE="main"
HEAD_BRANCH=""

# Parse arguments: support both --flag=value and --flag value
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo=*)
      REPO="${1#*=}"
      shift
      ;;
    --base=*)
      BASE="${1#*=}"
      shift
      ;;
    --head=*)
      HEAD_BRANCH="${1#*=}"
      shift
      ;;
    --title=*)
      TITLE="${1#*=}"
      shift
      ;;
    --body=*)
      BODY="${1#*=}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#*=}"
      shift
      ;;
    --state=*)
      STATE="${1#*=}"
      shift
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --base)
      BASE="${2:-}"
      shift 2
      ;;
    --head)
      HEAD_BRANCH="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --body)
      BODY="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --state)
      STATE="${2:-}"
      shift 2
      ;;
    *)
      fail "Unknown option: $1" 1
      ;;
  esac
done

# Determine Repository (Provided or Inferred)
REPO=$(get_repo "$REPO")

EXIT_CODE=0
RESULT=""
gh_cmd_args=()
[[ -n "$REPO" ]] && gh_cmd_args+=(--repo "$REPO")

# --- Operation Execution ---
case "$OP" in
  pr-create)
    [[ -z "$TITLE" ]] && fail "pr-create requires a title" 1
    gh_cmd_args+=(--title "$TITLE" --body "$BODY" --base "$BASE")
    [[ -n "$HEAD_BRANCH" ]] && gh_cmd_args+=(--head "$HEAD_BRANCH")
    RESULT=$(gh pr create "${gh_cmd_args[@]}" 2>&1) || EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 ]]; then
      pr_url=$(extract_url "$RESULT")
      jq -n --arg op "$OP" --arg title "$TITLE" --arg repo "$REPO" --arg base "$BASE" \
        --arg url "$pr_url" --argjson code "$EXIT_CODE" \
        '{success: true, operation: $op, title: $title, repo: $repo, base: $base, url: $url, exit_code: $code}'
    else
      jq -n --arg op "$OP" --arg title "$TITLE" --arg repo "$REPO" \
        --argjson code "$EXIT_CODE" --arg error "$RESULT" \
        '{success: false, operation: $op, title: $title, repo: $repo, exit_code: $code, error: $error}'
    fi
    ;;
  pr-list)
    gh_cmd_args+=(--limit "$LIMIT" --state "$STATE" --json number title state url author createdAt)
    RESULT=$(gh pr list "${gh_cmd_args[@]}" 2>&1) || EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 ]]; then
      printf "%s\n" "$RESULT" | jq -c --arg op "$OP" --arg repo "$REPO" '{success: true, operation: $op, repo: $repo, count: (. | length), prs: .}'
    else
      jq -n --arg op "$OP" --arg repo "$REPO" --argjson code "$EXIT_CODE" \
        --arg error "$RESULT" \
        '{success: false, operation: $op, repo: $repo, exit_code: $code, error: $error}'
    fi
    ;;
  issue-create)
    [[ -z "$TITLE" ]] && fail "issue-create requires a title" 1
    gh_cmd_args+=(--title "$TITLE" --body "$BODY")
    RESULT=$(gh issue create "${gh_cmd_args[@]}" 2>&1) || EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 ]]; then
      issue_url=$(extract_url "$RESULT")
      issue_num="0"
      [[ "$RESULT" =~ [0-9]+$ ]] && issue_num="${BASH_REMATCH[0]}"
      jq -n --arg op "$OP" --arg title "$TITLE" --arg repo "$REPO" \
        --arg url "$issue_url" --arg number "$issue_num" --argjson code "$EXIT_CODE" \
        '{success: true, operation: $op, title: $title, repo: $repo, number: $number, url: $url, exit_code: $code}'
    else
      jq -n --arg op "$OP" --arg title "$TITLE" --arg repo "$REPO" \
        --argjson code "$EXIT_CODE" --arg error "$RESULT" \
        '{success: false, operation: $op, title: $title, repo: $repo, exit_code: $code, error: $error}'
    fi
    ;;
  issue-list)
    gh_cmd_args+=(--limit "$LIMIT" --state "$STATE" --json number title state url author createdAt)
    RESULT=$(gh issue list "${gh_cmd_args[@]}" 2>&1) || EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 ]]; then
      printf "%s\n" "$RESULT" | jq -c --arg op "$OP" --arg repo "$REPO" '{success: true, operation: $op, repo: $repo, count: (. | length), issues: .}'
    else
      jq -n --arg op "$OP" --arg repo "$REPO" --argjson code "$EXIT_CODE" \
        --arg error "$RESULT" \
        '{success: false, operation: $op, repo: $repo, exit_code: $code, error: $error}'
    fi
    ;;
  *)
    fail "Unknown operation: $OP. Use pr-create, pr-list, issue-create, or issue-list" 1
    ;;
esac
