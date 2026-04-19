# Quick Start Guide

## 1. Copy Files to Your Flake

```bash
# Copy the main module
cp openclaw.nix /path/to/your/flake/

# Copy the OpenClaw folder
cp -r OpenClaw /path/to/your/flake/
```

Your flake structure should look like:
```
your-flake/
├── flake.nix
├── openclaw.nix          # Main entry point
├── OpenClaw/             # Module components
│   ├── modules/
│   ├── tools/
│   ├── providers/
│   └── docs/
└── secrets/
    └── openclaw.yaml     # SOPS secrets
```

## 2. Add to Your Flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix, ... }@inputs: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        ./openclaw.nix
        ./your-config.nix
      ];
    };
  };
}
```

## 3. Create Secrets

```bash
# Create secrets directory
mkdir -p secrets

# Create secrets file
cat > secrets/openclaw.yaml << 'EOF'
nvidia_api_key: nvapi-YOUR-KEY-HERE
gateway_auth_token: your-secure-random-token
EOF

# Encrypt with SOPS
sops secrets/openclaw.yaml
```

**Get NVIDIA API Key:** https://build.nvidia.com (free tier available)

## 4. Enable in Configuration

```nix
# your-config.nix
{
  services.openclaw = {
    enable = true;
    # Optional: customize
    # port = 18789;
    # defaultModel = "nvidia/meta/llama-3.3-70b-instruct";
  };
}
```

## 5. Rebuild

```bash
sudo nixos-rebuild switch --flake .#your-host
```

## 6. Verify

```bash
# Check service status
systemctl status openclaw

# Check logs
journalctl -u openclaw -f

# Test gateway (if configured)
curl http://127.0.0.1:18789/status
```

## Adding More Providers

Copy the template and edit:

```bash
cp OpenClaw/providers/_template.nix OpenClaw/providers/anthropic.nix
```

Add the API key to `secrets/openclaw.yaml`:

```yaml
anthropic_api_key: sk-ant-xxx
```

## Adding Custom Tools

Copy the template and edit:

```bash
cp OpenClaw/tools/_template.nix OpenClaw/tools/my-tool.nix
```

Rebuild to activate the new tool.

## Common Issues

| Issue | Solution |
|-------|----------|
| Service won't start | Check `journalctl -u openclaw` |
| API key not working | Verify SOPS decryption |
| Tool not found | Check `/var/lib/openclaw/tools/` |

## More Info

See `OpenClaw/docs/README.md` for full documentation.
