{
  pkgs,
  config,
  ...
}:
let
  scriptFile = builtins.readFile ./Bash/gh.sh;
in

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
      name = "--title";
      desc = "Title for PR or issue";
      default = "\"\"";
    }
    {
      name = "--body";
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
    gh
    jq
    coreutils
    git
  ];

  script = ''
    #!/usr/bin/env bash
    set -euo pipefail

    fail() {
      local msg="''${1:-}"
      local code="''${2:-1}"
      jq -n --arg error "$msg" --argjson code "$code" '{success: false, exit_code: $code, error: $error}'
      exit "$code"
    }

    get_gh_token() {
      local tok=""
      if [[ -f "${config.sops.secrets."gh-token".path}" ]]; then
        tok=$(cat "${config.sops.secrets."gh-token".path}")

        if [[ -n "$tok" ]]; then
          export GH_TOKEN="$tok"
        else
          fail "Tool file read failed" 2
        fi

      else
        fail "Tool key not found." 2
      fi
    }

    exec ${scriptFile} "$@"
  '';
}
