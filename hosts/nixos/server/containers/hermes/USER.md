# USER.md - About Adam

- **Name:** Adam
- **What to call him:** Adam
- **Timezone:** Europe/Warsaw
- **Language:** English (Polish when he switches)

## How He Works

- Prefers casual but direct communication. No fluff.
- Late-night coder — sometimes inactive for hours, sometimes fires off messages at 2am
- Annoyed by: tools that break silently, chained commands needing approval, empty defaults, overengineering (don't inject `coreutils`/`openssh` deps when remote PATH already has it; when Adam says "blindly" or "just", he means it — trust the infrastructure he already wired)
- Pushes back hard on fabrication ("don't be ridiculous, it's in <file>"; "there is a lot of options that are simply unexplained"). When the user's premise is provably wrong (e.g. file path is wrong, command they want doesn't exist, the thing they think is missing is actually declared in the flake), push back with the evidence in one turn instead of asking. When asking, ask once cleanly — no chained Clarify calls.
- When asking for "type a service file / config / snippet," defaults to wanting it live in the nix flake (nixos-conf/hosts/nixos/...), not a one-off `/etc/systemd/system` file. Check the flake first for existing declarations before writing anything.
- **Runs kanban cascades with `kanban.review_dispatch: false` so review-status cards WAIT for his explicit advance.** NEVER call `kanban complete --force` (or any other terminal verb) as a "cleanup" action after a worker reap, a protocol-guard loop, or any other "looks done-ish" signal — the card staying in `review` IS the correct terminal-to-the-board state and is required for his gate. Reaching for `complete --force` because "the worker is dead and the card looks done" advances the cascade prematurely and forces an archive+recreate dance to recover. When in doubt, surface the state and ASK before advancing. (2026-10-01, f95-renpy-manager card 3b: forced `complete --force` after a protocol-guard reap; he said "this is a catastrophe".)

## What He Works On

- NixOS configuration management via `nixos-conf` flake (at `git@amarek.pl:amarek/nixos-conf`, self-hosted Forgejo)
- Home server infrastructure (one nspawn container: Hermes)
- Custom tool development in Nix (lib wrappers with injected credentials via SOPS/SSH agent)
- Dev tooling and CI/CD automation

## Infrastructure

- **Hermes** (__HERMES_IP__) — this agent
- **NixOS flake:** `git@amarek.pl:amarek/nixos-conf`
- **Secrets:** SOPS-managed in `secrets/`
- **Discord:** user Atrys (ID: 323086933716893697), in his server
- **GitHub mirror:** AMarek05 (read-only fork of the Forgejo origin; legacy reference)

## Preferred Tools & Patterns

- Clean tooling with proper sandboxing — no half-measures
- Per-project: nixos-conf uses branch+PR (no direct main); f95-renpy-manager uses worktree branches — no PRs, the kanban board is the review surface

## Hard Limits

- Never commit secrets or credentials to git
- Never fabricate data or fake tool outputs
- Verify external claims — don't assume networking things "just work"
