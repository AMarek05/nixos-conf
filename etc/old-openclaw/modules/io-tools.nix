# modules/io-tools.nix
# Core I/O tools for the OpenClaw sandbox.
# These are the only tools the agent has access to by default.
# All paths are scoped to /var/lib/openclaw.

{ pkgs, ... }:
let
  workspace = "/var/lib/openclaw";

  # TOOL 1: Safe File Reader
  # Reads a file from the workspace. Paths are relative to /var/lib/openclaw.
  # Usage: safe-read <relative-path>
  safeReadFile = pkgs.writeShellScriptBin "safe-read" ''
    set -euo pipefail

    if [ -z "''${1:-}" ]; then
      echo "Usage: safe-read <filepath>"
      echo "  Reads a file from the workspace."
      echo "  Paths are relative to ${workspace}"
      exit 1
    fi

    # Strip leading slashes to prevent absolute path injection
    REL_PATH="''${1#/}"

    FILE_PATH="${workspace}/$REL_PATH"

    # Resolve and verify the path stays within workspace
    RESOLVED="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"
    if [[ "$RESOLVED" != "${workspace}"* ]]; then
      echo "Error: Path escapes workspace boundaries."
      exit 1
    fi

    if [ -f "$FILE_PATH" ]; then
      cat "$FILE_PATH"
    elif [ -d "$FILE_PATH" ]; then
      echo "Error: $1 is a directory, not a file. Use safe-tree to explore."
      exit 1
    else
      echo "Error: File $1 does not exist in workspace."
      exit 1
    fi
  '';

  # TOOL 2: Safe File Writer
  # Creates or overwrites a file in the workspace. Paths are relative to /var/lib/openclaw.
  # Usage: safe-write <relative-path> "<content>"
  safeWriteFile = pkgs.writeShellScriptBin "safe-write" ''
    set -euo pipefail

    if [ -z "''${1:-}" ] || [ -z "''${2:-}" ]; then
      echo "Usage: safe-write <filepath> \"<content>\""
      echo "  Writes content to a file in the workspace."
      echo "  Paths are relative to ${workspace}"
      echo "  Creates parent directories automatically."
      exit 1
    fi

    # Strip leading slashes to prevent absolute path injection
    REL_PATH="''${1#/}"

    FILE_PATH="${workspace}/$REL_PATH"

    # Resolve the directory portion and verify it stays within workspace
    PARENT_DIR="$(dirname "$FILE_PATH")"
    mkdir -p "$PARENT_DIR"

    RESOLVED_PARENT="$(cd "$PARENT_DIR" && pwd)"
    if [[ "$RESOLVED_PARENT" != "${workspace}"* ]]; then
      echo "Error: Path escapes workspace boundaries."
      exit 1
    fi

    # Write the file (content is the second argument)
    CONTENT="$2"
    printf '%s' "$CONTENT" > "$FILE_PATH"
    echo "Success: Wrote to $1"
  '';

  # TOOL 3: Safe Tree
  # Lists the workspace directory structure.
  # Usage: safe-tree [subpath]
  safeTree = pkgs.writeShellScriptBin "safe-tree" ''
    set -euo pipefail

    # Strip leading slashes
    REL_PATH="''${1#/}"

    TARGET="${workspace}/''${REL_PATH:-.}"

    # Resolve and verify the path stays within workspace
    RESOLVED="$(cd "$TARGET" 2>/dev/null && pwd)"
    if [[ "''${RESOLVED:-}" != "${workspace}"* ]]; then
      echo "Error: Path escapes workspace boundaries or does not exist."
      exit 1
    fi

    if [ ! -d "$TARGET" ]; then
      echo "Error: Directory does not exist."
      exit 1
    fi

    ${pkgs.tree}/bin/tree --dirsfirst -a \
      -I '.git' \
      "$TARGET"
  '';

in
{
  # Add the tool scripts to the gateway service PATH
  systemd.services.openclaw-gateway.path = [
    safeReadFile
    safeWriteFile
    safeTree
  ];
}
