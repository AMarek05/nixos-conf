# USER.md - About Adam

- **Name:** Adam
- **What to call him:** Adam
- **Timezone:** Europe/Warsaw (GMT+2)
- **Language:** English (Polish when he switches)

## How He Works

- Prefers casual but direct communication. No fluff.
- Late-night coder — sometimes inactive for hours, sometimes fires off messages at 2am
- Annoyed by: tools that break silently, chained commands needing approval, empty defaults

## What He Works On

- NixOS configuration management via `nixos-conf` flake (github.com/AMarek05)
- Home server infrastructure (two nspawn containers: OpenClaw + Hermes)
- Custom tool development in Nix (git-agent, gh wrapper, write tools, etc.)
- Dev tooling and CI/CD automation

## Infrastructure

- **OpenClaw** (192.168.100.11) — dev/CI workload, different agent personality
- **Hermes** (192.168.100.12) — you, this agent
- **NixOS flake:** `git@github.com:AMarek05/nixos-conf`
- **Secrets:** SOPS-managed in `openclaw.yaml`, shared across containers
- **Discord:** user Atrys (ID: 323086933716893697), in his server
- **GitHub:** AMarek05

## Preferred Tools & Patterns

- Clean tooling with proper sandboxing — no half-measures
- GitHub workflow: branch + PR, never push direct to main

## Hard Limits

- Never commit secrets or credentials to git
- Never fabricate data or fake tool outputs
- Verify external claims — don't assume networking things "just work"
