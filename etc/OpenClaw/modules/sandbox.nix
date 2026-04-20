# OpenClaw Sandbox Configuration
#
# This module configures the sandbox environment for OpenClaw's tools,
# ensuring that file operations are restricted to the designated workspace.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;

  # Wrapper script for sandboxed command execution
  sandboxWrapper = pkgs.writeShellScriptBin "openclaw-sandbox-exec" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Workspace boundary
    WORKSPACE="${cfg.workspace}"
    ALLOWED_PATHS="$WORKSPACE:$WORKSPACE/workspace:$WORKSPACE/tools"

    # Validate path is within workspace
    validate_path() {
      local path="$1"
      local resolved=""
      
      # Resolve to absolute path
      if [[ -e "$path" ]]; then
        resolved="$(readlink -f "$path")"
      else
        resolved="$(cd "$(dirname "$path")" 2>/dev/null && readlink -f "$(basename "$path")" 2>/dev/null || echo "$path")"
      fi
      
      # Check if path starts with an allowed prefix
      local allowed=0
      IFS=':' read -ra PATHS <<< "$ALLOWED_PATHS"
      for prefix in "''${PATHS[@]}"; do
        if [[ "$resolved" == "$prefix"* ]]; then
          allowed=1
          break
        fi
      done
      
      if [[ $allowed -eq 0 ]]; then
        echo "ERROR: Path '$path' is outside the allowed workspace" >&2
        return 1
      fi
      return 0
    }

    # Run the command with validation
    case "''${1:-}" in
      read|cat|ls|stat|file)
        validate_path "$2" || exit 1
        ;;
      write|mkdir|rm|mv|cp)
        validate_path "$2" || exit 1
        [[ -n "''${3:-}" ]] && validate_path "$3" || true
        ;;
      exec)
        echo "ERROR: Arbitrary execution not allowed in sandbox" >&2
        exit 1
        ;;
    esac

    exec "$@"
  '';

in
{
  config = lib.mkIf cfg.enable {
    # Create sandbox wrapper in system path
    environment.systemPackages = [ sandboxWrapper ];

    # AppArmor profile for additional sandboxing (optional but recommended)
    security.apparmor.policies = lib.mkIf config.security.apparmor.enable {
      openclaw = {
        enable = true;
        enforce = true;
        profile = ''
          ${lib.getExe cfg.package} {
            # Basic capabilities
            capability dac_read_search,
            capability dac_override,

            # Network access for API calls
            network inet stream,
            network inet6 stream,
            network unix stream,
            
            # Read access to system files
            /etc/resolv.conf r,
            /etc/hosts r,
            /etc/nsswitch.conf r,
            /etc/ssl/certs/** r,
            /nix/store/** r,
            
            # Full access to workspace
            ${cfg.workspace}/** rwl,
            ${cfg.workspace}/workspace/** rwl,
            ${cfg.workspace}/tools/** rwl,
            
            # Deny everything else
            deny /** rwlx,
            deny @{PROC}/** rwlx,
            deny /sys/** rwlx,
          }
        '';
      };
    };

    # System-level sandbox configuration file
    environment.etc."openclaw/sandbox.conf".text = ''
      # OpenClaw Sandbox Configuration
      # This file defines the sandbox boundaries for OpenClaw

      WORKSPACE=${cfg.workspace}
      ALLOWED_PATHS=${cfg.workspace},${cfg.workspace}/workspace,${cfg.workspace}/tools
      DENIED_PATHS=/etc/shadow,/etc/passwd,/etc/ssh,/root,/home,/var/lib/secrets

      # Tool execution settings
      ALLOW_EXEC=false
      TIMEOUT_SECONDS=300

      # Resource limits for tools
      MAX_FILE_SIZE_BYTES=104857600
      MAX_OUTPUT_BYTES=10485760
    '';

    # Ensure the sandbox config is readable by openclaw user
    systemd.tmpfiles.rules = [
      "z /etc/openclaw 0755 root root - -"
    ];
  };
}
