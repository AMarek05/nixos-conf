# lib/git.nix
{ config, pkgs }:
let
  git-wrapper = pkgs.writeShellScriptBin "git" ''
    set -euo pipefail

    SSH_KEY_PATH="${config.sops.secrets."claw-ssh-key".path}"

    if [[ -f "$SSH_KEY_PATH" ]]; then
      # Create a persistent allowedSignersFile once (reuse on subsequent calls)
      # Format: "<principal> <key-type> <key>" — ssh-keygen output lacks the principal
      SIGNERS_FILE="$HOME/.ssh/allowed_signers"
      if [[ ! -f "$SIGNERS_FILE" ]]; then
        PUBKEY=$(${pkgs.openssh}/bin/ssh-keygen -y -f "$SSH_KEY_PATH" 2>/dev/null)
        echo "278452676+amarek-machine@users.noreply.github.com $PUBKEY" > "$SIGNERS_FILE"
      fi

      # Configure git to use this signers file for verification
      ${pkgs.git}/bin/git config --global gpg.ssh.allowedSignersFile "$SIGNERS_FILE"


      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes"

      # Execute the real git, injecting the SSH signing rules statelessly
      exec ${pkgs.git}/bin/git \
        -c user.name="Claw" \
        -c user.email="278452676+amarek-machine@users.noreply.github.com" \
        -c g.branch.autosetuprebase=always \
        -c gpg.format=ssh \
        -c user.signingkey="$SSH_KEY_PATH" \
        -c commit.gpgsign=true \
        "$@"
    else
      # Fallback to standard git if the key hasn't been provisioned yet
      exec ${pkgs.git}/bin/git "$@"
    fi
  '';
in
git-wrapper
