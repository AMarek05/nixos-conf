# OpenClaw Tool Template
#
# This is a template for creating new tools for OpenClaw.
# Copy this file and modify the sections below.
#
# Tools are shell scripts that run within the OpenClaw sandbox.
# They have access to:
#   - nixpkgs binaries (via PATH)
#   - The workspace at /var/lib/openclaw
#   - Environment variables set by OpenClaw
#
# Tools do NOT have access to:
#   - Files outside the workspace
#   - Network (unless explicitly granted)
#   - Root privileges
#
# To create a new tool:
# 1. Copy this template to a new file: cp _template.nix my-tool.nix
# 2. Modify the name, description, and script
# 3. Rebuild your NixOS system
# 4. The tool will appear in /var/lib/openclaw/tools/
#
# Alternatively, use the forge-tool tool to create tools interactively!

{
  pkgs,
  cfg,
  ...
}:

{
  # Required: Tool name (becomes the filename)
  name = "my-example-tool";

  # Required: Human-readable description
  description = "A template tool for OpenClaw";

  # Optional: File permissions (default: 0750)
  permissions = "0750";

  usage = "_template [arguments]";

  arguments = [
    {
      name = "arg1";
      desc = "Example first argument (path)";
      default = "required";
    }
    {
      name = "arg2";
      desc = "Example second argument (options)";
      default = "-";
    }
  ];

  examples = [
    "_template workspace/test-file.txt"
    "cat _template.nix > my-new-tool.nix"
  ];

  # Optional: Dependencies from nixpkgs
  dependencies = with pkgs; [
    coreutils
    jq
  ];

  # Required: The shell script content
  # Use ${cfg.workspace} as a placeholder for the workspace path
  script = ''
    # OpenClaw Tool: my-tool
    # Description: A template tool for OpenClaw
    #
    # Usage: my-tool [arguments]
    #
    # Arguments:
    #   $1 - Description of first argument
    #   $2 - Description of second argument
    #
    # Output:
    #   JSON object with result or error
    #
    # Exit codes:
    #   0 - Success
    #   1 - Error (user error, invalid input)
    #   2 - System error (permissions, resource unavailable)

    set -euo pipefail

    # Workspace path (injected by tools-loader)
    WORKSPACE="${cfg.workspace}"

    # Validate we're in a safe directory
    cd "$WORKSPACE/workspace"

    # Parse arguments
    ARG1="''${1:-}"
    ARG2="''${2:-}"

    if [[ -z "$ARG1" ]]; then
      echo '{"error": "Missing required argument: ARG1"}'
      exit 1
    fi

    # Validate path is within workspace
    validate_path() {
      local path="$1"
      local resolved
      resolved="$(readlink -f "$path")"
      
      if [[ ! "$resolved" =~ ^"$WORKSPACE" ]]; then
        echo "{\"error\": \"Path '$path' is outside workspace\"}"
        exit 1
      fi
      echo "$resolved"
    }

    # Main logic
    main() {
      local safe_path
      safe_path="$(validate_path "$ARG1")"
      
      # Your tool logic here
      echo "{\"success\": true, \"result\": \"$safe_path\"}"
    }

    main "$@"
  '';
}
