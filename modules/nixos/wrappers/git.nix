# modules/nixos/wrappers/git.nix
#
# Transparent `git` wrapper that wires the claw-ssh-key for SSH and signing.
#
# The SOPS secret `sops.secrets."claw-ssh-key"` MUST be declared in this
# evaluation (typically in the host or container config). The wrapper is
# also installed without the secret at build time — the script falls back
# to plain `git` if the secret file isn't present, so the module can be
# imported unconditionally; only an assertion fires at eval time when
# enable=true but the secret is missing.
#
# Consumers:
#   imports = [ myLib.gitWrapper ];
#
# Reference the wrapper package via `config.services.git-wrapper.package`
# when pinning onto a systemd.path (e.g. update-attic.service).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.git-wrapper;

  secretName = "claw-ssh-key";
  secretPath = config.sops.secrets.${secretName}.path or null;

  package = pkgs.writeShellScriptBin "git" ''
    set -euo pipefail

    SSH_KEY_PATH="${toString secretPath}"

    if [[ -f "$SSH_KEY_PATH" ]]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"

      exec ${pkgs.git}/bin/git \
        -c user.name="${cfg.signing.name}" \
        -c user.email="${cfg.signing.email}" \
        -c g.branch.autosetuprebase=always \
        -c gpg.format=ssh \
        -c user.signingkey="$SSH_KEY_PATH" \
        -c commit.gpgsign=true \
        -c push.autoSetupRemote=true \
        "$@"
    else
      exec ${pkgs.git}/bin/git "$@"
    fi
  '';
in
{
  options.services.git-wrapper = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the claw-ssh-key-aware `git` wrapper.

        Reads the path of `sops.secrets."claw-ssh-key"` (which must be
        declared in the same evaluation) and bakes it into the wrapper
        at build time. Falls back to plain `git` at use time if the
        secret file is missing on disk.
      '';
    };

    signing = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Claw";
        description = "Git user.name baked into the wrapper.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "278452676+amarek-machine@users.noreply.github.com";
        description = "Git user.email baked into the wrapper.";
      };
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
          services.git-wrapper is enabled, but sops.secrets."${secretName}"
          is not declared in this evaluation. Either declare the SOPS
          secret (e.g. in the host or container config) or set
          services.git-wrapper.enable = false.
        '';
      }
    ];

    environment.systemPackages = [ cfg.package ];
  };
}
