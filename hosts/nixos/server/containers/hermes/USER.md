# USER.md - About Adam

- **Name:** Adam
- **What to call him:** Adam
- **Timezone:** Europe/Warsaw
- **Language:** English (Polish when he switches)

## How He Works

- Prefers casual but direct communication. No fluff.
- Late-night coder — sometimes inactive for hours, sometimes fires off messages at 2am
- Annoyed by: tools that break silently, chained commands needing approval, empty defaults

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
- Forgejo workflow: branch + PR, never push direct to main

## Hard Limits

- Never commit secrets or credentials to git
- Never fabricate data or fake tool outputs
- Verify external claims — don't assume networking things "just work"
