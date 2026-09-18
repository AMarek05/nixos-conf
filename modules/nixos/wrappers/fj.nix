# modules/nixos/wrappers/fj.nix
#
# Wrapper around `forgejo-cli` (`fj`) that injects the auth token from
# the SOPS-managed secret `sops.secrets."fj-auth"` at use time.
#
# The SOPS secret MUST be declared in this evaluation. The wrapper
# re-authenticates on each invocation when the secret is newer than a
# state file under `~/.cache/fj-token-synced`, otherwise it falls
# through to the underlying `fj` binary.
#
# Consumers:
#   imports = [ myLib.fjWrapper ];
#
# Reference the wrapper package via `config.services.fj-wrapper.package`
# when pinning onto a systemd.path.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.fj-wrapper;

  secretName = "fj-auth";
  secretPath = config.sops.secrets.${secretName}.path or null;

  package = pkgs.writeShellScriptBin "fj" ''
    set -euo pipefail

    FJ_AUTH_PATH="${toString secretPath}"
    STATE_FILE="$HOME/.cache/fj-token-synced"

    if [[ -f "$FJ_AUTH_PATH" ]]; then
      if [[ ! -f "$STATE_FILE" ]] || [[ "$FJ_AUTH_PATH" -nt "$STATE_FILE" ]]; then
        TOKEN="$(cat "$FJ_AUTH_PATH")"

        ${pkgs.forgejo-cli}/bin/fj --host "${cfg.host}" auth add-key Claw "$TOKEN" >/dev/null 2>&1 || true

        mkdir -p "$(dirname "$STATE_FILE")"
        touch "$STATE_FILE"
      fi
    fi

    exec ${pkgs.forgejo-cli}/bin/fj --host "${cfg.host}" "$@"
  '';
in
{
  options.services.fj-wrapper = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the `fj` wrapper that injects the auth token from
        `sops.secrets."fj-auth"` (which must be declared in the same
        evaluation).
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "https://git.amarek.pl";
      description = "Forgejo instance the wrapper targets.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      visible = false;
      default = package;
      description = ''
        The wrapper derivation. Pin onto `systemd.services.<name>.path`
        when the wrapper must be available to a service but not on
        `$PATH`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.sops.secrets ? ${secretName};
        message = ''
          services.fj-wrapper is enabled, but sops.secrets."${secretName}"
          is not declared in this evaluation. Either declare the SOPS
          secret (e.g. in the host or container config) or set
          services.fj-wrapper.enable = false.
        '';
      }
    ];

    environment.systemPackages = [ cfg.package ];
  };
}
