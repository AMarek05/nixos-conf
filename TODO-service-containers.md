# Service Container Migration Plan

## Context

The OpenClaw container was the proof-of-concept for the containerization pattern in `hosts/nixos/server/default.nix`. All other host services currently live directly on the host. This is not ideal for isolation, upgrade hygiene, and reproducibility.

## Container Creation Pattern

Each container follows this structure in `hosts/nixos/server/default.nix`:

```nix
containers.<name> = {
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.100.10";
  localAddress = "192.168.100.11";

  specialArgs = { inherit inputs; };

  config = { ... }: {
    imports = [ ./containers/<name>.nix ];
  };

  bindMounts = {
    "/path/on/host" = {
      hostPath = "/path/on/host";
      isReadOnly = true;
    };
  };
};
```

The container guest config lives at `hosts/nixos/server/containers/<name>.nix`.

Static networking: each container gets an address on the `ve-+` internal network (e.g. `.12`, `.13`, etc.). The host NATs this network to the outside.

---

## Proposed Groupings

### 1. `media` — Jellyfin + Plex + qBittorrent + PVR stack

**Rationale:** These are all media-related, frequently accessed together, and benefit from shared GPU/DRI access. qBittorrent is the download ingestion point for the PVR stack.

**Services:**
- `services.jellyfin` — port 8096, QSV hardware transcoding, `/dev/dri/renderD128`
- `services.plex` — port 32469
- `services.qbittorrent` — webuiPort 8080
- `services.sonarr`, `services.radarr`, `services.bazarr`

**Container networking:** `localAddress = "192.168.100.12"`
**Bind mounts:** `/media` (the large data disk), SOPS secrets if needed for download client auth
**Host networking:** `openFirewall = true` already set on jellyfin/plex/qbit/bazarr/sonarr/radarr — firewall rules stay on host NAT side
**Special considerations:**
- Jellyfin QSV needs `/dev/dri/renderD128` passed through — use `containers.<name>.bindMounts` + `extraOptions = [ "--device=/dev/dri/renderD128" ]`
- Plex also uses GPU for transcoding — same treatment
- All three write to `/media`, which is already a bind mount on the host
- Sonarr/Radarr/Bazarr user groups — container must define users or use `容器的extraGroups`

**Caddy reverse proxy** stays on host (or moves to its own container — see below).

---

### 2. `proxy` — Caddy + ACME

**Rationale:** Caddy handles TLS termination for everything. It needs port 80/443 and must be reachable by the ACME challenge. Centralizing it avoids duplicate certificate requests and makes cert management simpler.

**Services:**
- `services.caddy` — all virtual host definitions currently in `server/default.nix`
- `security.acme` — the `amarek.org` cert definition

**Container networking:** `localAddress = "192.168.100.13"`
**Bind mounts:** none needed if SOPS secrets are passed for Cloudflare DNS token
**Special considerations:**
- ACME DNS challenge needs `CLOUDFLARE_DNS_API_TOKEN_FILE` — SOPS secret is already on the host at `/var/lib/sops-nix/secrets/serv.yaml`, needs to be bind-mounted or passed via `sopsFile` path inside the container
- Caddy's `virtualHosts` configs proxy to the other containers' `192.168.100.x` addresses — these must be reachable on the internal network
- Port 80/443 must be allowed through the host firewall and NATed to the container

**Alternative:** Keep Caddy+ACME on the host and only containerize the app services. This avoids the complexity of passing through the ACME challenge. ACME DNS challenge works without port 80/443 so this is viable. **Decide before implementing.**

---

### 3. `ai` — SillyTavern + Newt

**Rationale:** AI chat interface + backend. Newt is the API bridge. These two are tightly coupled and both are relatively lightweight.

**Services:**
- `services.sillytavern` — port 8000, custom config file
- `services.newt` — environment-backed API service

**Container networking:** `localAddress = "192.168.100.14"`
**Bind mounts:** SillyTavern `configFile` at `/var/lib/SillyTavern/config.yaml.bak` needs bind mount if it lives on the host
**Special considerations:**
- SillyTavern's `postInstall` overlay hook creates a directory in the nix store — fine inside the container
- Newt needs its `environmentFile` SOPS secret — pass via bind mount or re-define sops secret inside the container

---

### 4. `forgejo` — Self-hosted Git

**Rationale:** Forgejo is a long-running service with persistent state (git repos, DB). Isolating it gives clean upgrade boundaries.

**Services:**
- `services.forgejo` — port 3000, custom domain `git.amarek.org`

**Container networking:** `localAddress = "192.168.100.15"`
**Bind mounts:** `/var/lib/forgejo` (data directory) from host
**Special considerations:**
- Forgejo needs SSH (port 22 inside container or host-side port 22 forwarded)
- If the container's SSH daemon handles git, the host needs to route port 2222→container:22 or similar
- The `settings.server.DOMAIN` and `ROOT_URL` are already configured — may need adjusting for the new container address

---

### 5. Host-only残留 — What stays on the host

| Service | Reason to keep on host |
|---------|------------------------|
| `containers.openclaw` | Already containerized |
| `networking.nat` | Host-level routing, cannot be containerized |
| `networking.firewall` | Host-level iptables/nftables |
| `sops.age` + `sops.secrets` | Secrets are on the host filesystem; re-exported to containers via bind mounts |
| `fileSystems."/media"` | Physical disk mount, must be on host |
| `boot.loader` | Cannot be containerized |
| SSH (port 22) | Host-level |
| Tailscale/WireGuard | VPN terminates at host network layer |
| `systemd.services."container@*"` | Container lifecycle management |

---

## Migration Order

1. **Create `hosts/nixos/server/containers/` directory** — scaffold the directory
2. **`proxy` container** — Most disruptive (all traffic routes through it). Only do this if the "keep Caddy on host" alternative is rejected. Otherwise skip.
3. **`media` container** — Most complex (GPU passthrough, multi-service). Do second.
4. **`ai` container** — Simple, low-risk. Do third.
5. **`forgejo` container** — Medium complexity (SSH routing). Do last.
6. **Remove services from `server/default.nix`** — Delete from host config once each container is verified working.

## Testing Checklist

- [ ] Container starts and stays up (`systemctl status container@<name>`)
- [ ] Service is reachable on its internal IP:port
- [ ] Caddy reverse proxy routes correctly to the new internal IPs
- [ ] ACME certs are re-issued or reused correctly (DNS challenge)
- [ ] Jellyfin/Plex hardware transcoding works with `/dev/dri` passthrough
- [ ] qBittorrent can reach tracker DHT on the host network
- [ ] Media files on `/media` are accessible inside the container
- [ ] No port conflicts on host
- [ ] `nixos-rebuild switch --flake .#nixos-server` completes without error

## Notes

- The `192.168.100.x` address space is already routed via `ve-+` NAT. No new network config needed for additional containers — just assign new IPs.
- WireGuard (port 51820 UDP) and Tailscale (21820 UDP) stay on the host.
- Each container's `bindMounts` should use `isReadOnly = true` where the host doesn't need to write.
- SOPS secrets are re-used by bind-mounting the sopsFile or the individual secret paths. Alternatively, each container can import `inputs.sops-nix.nixosModules.sops` and reference the same `sopsFile`.
