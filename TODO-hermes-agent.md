# Hermes Agent — NixOS nspawn Container Integration

## Context

[Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research is a self-improving Python-based AI agent with built-in memory, skills, multi-platform messaging (Discord, Telegram, Signal, WhatsApp, etc.), and terminal backends. Its NixOS flake module (`nix/nixosModules.nix`) provides `services.hermes-agent` in two modes:

| Hermes flake mode | Description |
|------------------|-------------|
| `container.enable = false` | Native systemd service |
| `container.enable = true` | OCI container (Docker/Podman) with persistent writable layer |

**Adam's requirement:** Run Hermes Agent in a **hardened NixOS systemd-nspawn container** — same approach as the existing OpenClaw container — not Docker/Podman.

---

## Feasibility Assessment

**TL;DR: ✅ Feasible, with caveats.**

### Why it works

- Hermes Agent is a Python CLI application (`hermes`, `hermes gateway`) that can run on any Linux system with Python 3.11+
- The NixOS nspawn container approach (as used for OpenClaw at `192.168.100.11`) can host Hermes just as easily
- The hermes-agent flake package (`packages.default`) is a working Python package built via `uv2nix`
- The existing SOPS secrets (`minimax-api-key`) can be reused for the Minimax provider
- Network topology is already established: `ve-+` internal network, NAT on host, static IPs per container

### Caveats / Challenges

1. **Hermes flake's container mode is Docker/Podman** — we will NOT use it. Instead, we define our own NixOS nspawn container (same pattern as OpenClaw).

2. **Python environment** — Hermes expects a writable Python venv (`~/.venv`) for agent self-modification (`pip install`, `uv tool install`). Our nspawn container's NixOS root is read-only by design (`ProtectSystem = "full"`). The agent's writable space is `stateDir` (`/var/lib/hermes`) which is a bind mount — **this is fine**, the agent writes to `/var/lib/hermes`, not to the nix store.

3. **No pre-built NixOS hermes module** — we must write a NixOS container guest config from scratch (similar to `hosts/nixos/server/openclaw.nix`). The Hermes flake's `services.hermes-agent` module is designed for bare metal or Docker, not nspawn.

4. **Two systemd services**: Both OpenClaw and Hermes will run as systemd services on the host, managing their respective containers. We need to avoid port conflicts (OpenClaw uses `18789`, Hermes likely different).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Host (NixOS)                              │
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │  openclaw container  │    │  hermes-agent container│          │
│  │  (nspawn)            │    │  (nspawn)             │          │
│  │  192.168.100.11      │    │  192.168.100.12       │          │
│  │  port 18789          │    │  port 18792 (TBC)      │          │
│  └──────────┬───────────┘    └──────────┬───────────┘          │
│             │                           │                       │
│         ve-+                       ve-+                        │
│             └────────┬────────────────┘                        │
│                      │                                         │
│              NAT (ens18)                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1 — Flake Integration
- [ ] Add `hermes-agent` input to `flake.nix` (follows `nixpkgs`, `flake-parts`)
- [ ] Run `nix flake update` to lock the input
- [ ] Add `hermes-agent` to `hosts/nixos/server/default.nix` container definitions

### Phase 2 — Container Guest Config
- [ ] Create `hosts/nixos/server/hermes.nix` — NixOS guest config for hermes-agent container
  - Static IP: `192.168.100.12`
  - `hermes-agent` package available via `hermes` CLI
  - Runtime dependencies (Node.js, Python, uv) bootstrapped by container entrypoint on first boot — no explicit systemPackages needed
  - SOPS secrets: `hermes-api-key` (reuse or new), `minimax-api-key`
  - Working directory: `/var/lib/hermes/workspace` (bind mounted from host)
  - Hardened systemd service (same pattern as OpenClaw)

### Phase 3 — Host Container Definition
- [ ] Add `containers.hermes-agent` to `hosts/nixos/server/default.nix`
  - `autoStart = true`, `privateNetwork = true`
  - `hostAddress = "192.168.100.10"`, `localAddress = "192.168.100.12"`
  - `specialArgs = { inherit inputs; }`
  - Bind mounts: SOPS age key, `/var/lib/hermes` workspace, secrets
- [ ] Update `networking.nat` / firewall if needed

### Phase 4 — Hermes Configuration
- [ ] Configure `hermes model` provider (Minimax via `MINIMAX_API_KEY`)
- [ ] Configure messaging platforms (Discord, Telegram, etc.)
- [ ] Configure MCP servers if needed
- [ ] Set up initial documents (SOUL.md, USER.md, AGENTS.md)
- [ ] Test: `hermes gateway start` inside the container

### Phase 5 — Validation
- [ ] `nixos-rebuild switch --flake .#nixos-server` succeeds
- [ ] Container starts and stays up
- [ ] Hermes responds to test message via configured platform
- [ ] Minimax API key works for model calls
- [ ] No port conflicts with OpenClaw

---

## Open Questions

~~4. **Users/groups** — Should the hermes container run as user `hermes` (like the hermes flake default) or reuse `openclaw` user? Best to use a dedicated `hermes` user for clarity.**~~ — Solved by `services.hermes-agent` module: it has `createUser = true` and creates `hermes` user/group automatically.

~~5. **Migration from OpenClaw** — Hermes can import OpenClaw state (`hermes claw migrate`). Should this be run as part of setup? Probably post-deployment step.**~~ — Post-deployment step. Not a NixOS config concern. Run `hermes claw migrate` manually after first successful deployment.

### Remaining questions

1. **Hermes default port** — What port does `hermes gateway` listen on? Need to verify or configure explicitly to avoid collision with OpenClaw's `18789`.

2. **Caddy routing** — Should `hermes.amarek.org` route to Hermes container via Caddy on host? Add virtual host entry or keep separate?

3. **SOPS secret naming** — Create a new `hermes-api-key` in `secrets/openclaw.yaml`, or reuse `minimax-api-key`? Adam has `minimax-api-key` already. Should Hermes use the same or a dedicated one?

---

## Files to Create/Modify

```
flake.nix                                    [modify — add hermes-agent input]
hosts/nixos/server/default.nix               [modify — add containers.hermes-agent]
hosts/nixos/server/hermes.nix                [create — new container guest config]
secrets/openclaw.yaml                       [modify — add hermes-api-key]
hosts/nixos/server/default.nix               [modify — Caddy route for hermes subdomain?]
```

---

## References

- Hermes Agent repo: https://github.com/NousResearch/hermes-agent
- Hermes NixOS module: `nix/nixosModules.nix` in that repo
- OpenClaw container as reference: `hosts/nixos/server/openclaw.nix`
- Existing `TODO-service-containers.md` for container pattern