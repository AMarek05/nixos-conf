{
  pkgs,
  config,
  ...
}:

{
  name = "gh";
  permissions = "0750";
  description = "GitHub CLI transparent wrapper";
  usage = "Typical gh";

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

    get_gh_token

    exec "${pkgs.gh}/bin/gh" "$@"
  '';
}
