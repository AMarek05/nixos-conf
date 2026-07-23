# lib/git.nix
{ config, pkgs }:
let
  git-wrapper = pkgs.writeShellScriptBin "git" ''
    set -euo pipefail

    SSH_KEY_PATH="${config.sops.secrets."claw-ssh-key".path}"

    if [[ -f "$SSH_KEY_PATH" ]]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"

      # Execute the real git, injecting the SSH signing rules statelessly
      exec ${pkgs.git}/bin/git \
        -c user.name="Claw" \
        -c user.email="278452676+amarek-machine@users.noreply.github.com" \
        -c g.branch.autosetuprebase=always \
        -c gpg.format=ssh \
        -c user.signingkey="$SSH_KEY_PATH" \
        -c commit.gpgsign=true \
        -c push.autoSetupRemote=true \
        "$@"
    else
      # Fallback to standard git if the key hasn't been provisioned yet
      exec ${pkgs.git}/bin/git "$@"
    fi
  '';
in
git-wrapper
