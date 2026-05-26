# OpenClaw Hardened NixOS Module

A security-hardened NixOS module for running OpenClaw, an open-source personal AI assistant platform. This module provides comprehensive sandboxing, modular tooling, and seamless integration with SOPS secrets.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Directory Structure](#directory-structure)
4. [Configuration](#configuration)
5. [Adding Providers](#adding-providers)
6. [Creating Tools](#creating-tools)
7. [Security Hardening](#security-hardening)
8. [SOPS Integration](#sops-integration)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This module provides:

- **Hardened SystemD Service**: Comprehensive sandboxing with filesystem isolation, system call filtering, and capability restrictions
- **Modular Tooling System**: Extensible tools that can be added without modifying core configuration
- **SOPS Secrets Integration**: Secure management of API keys and credentials
- **NVIDIA NIM Default**: Pre-configured for NVIDIA's free model access
- **Auto-loading Tools**: Simply drop `.nix` files into the tools directory

### What is OpenClaw?

OpenClaw is an open-source AI assistant platform that:
- Connects to multiple AI providers (Anthropic, OpenAI, NVIDIA, Google, etc.)
- Supports multiple channels (Discord, Slack, Telegram, WhatsApp, Web UI)
- Provides extensible tools and skills
- Runs entirely on your infrastructure

---

## Quick Start

### 1. Add to Your Flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    
    # Copy the openclaw.nix and OpenClaw/ folder to your flake root
  };
  
  outputs = { self, nixpkgs, sops-nix, ... }@inputs: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        ./openclaw.nix  # Main module entry point
        
        # Your other configuration...
      ];
    };
  };
}
```

### 2. Create Secrets File

Create `secrets/openclaw.yaml` in your flake:

```yaml
# NVIDIA NIM API key (required for default provider)
nvidia_api_key: nvapi-xxx

# Optional: Additional provider keys
anthropic_api_key: sk-ant-xxx
openai_api_key: sk-xxx

# Gateway authentication token
gateway_auth_token: your-secure-random-token
```

Encrypt with SOPS:

```bash
sops secrets/openclaw.yaml
```

### 3. Enable the Service

```nix
# configuration.nix or similar
{
  services.openclaw = {
    enable = true;
    
    # Optional: Override defaults
    port = 18789;
    defaultModel = "nvidia/meta/llama-3.3-70b-instruct";
  };
}
```

### 4. Rebuild

```bash
sudo nixos-rebuild switch --flake .#your-host
```

---

## Directory Structure

```
your-flake/
├── flake.nix
├── openclaw.nix              # Main entry point
├── OpenClaw/
│   ├── modules/
│   │   ├── user.nix          # User/group creation
│   │   ├── systemd.nix       # Hardened service definition
│   │   ├── sandbox.nix       # Sandbox configuration
│   │   ├── sops.nix          # Secrets integration
│   │   └── tools-loader.nix  # Auto-loading tools
│   ├── tools/
│   │   ├── _template.nix     # Tool template
│   │   ├── read-file.nix     # Read files in workspace
│   │   ├── write-file.nix    # Write files in workspace
│   │   ├── forge-tool.nix    # Create new tools
│   │   └── your-tools/       # Add your tools here
│   ├── providers/
│   │   ├── _template.nix     # Provider template
│   │   └── nvidia-nim.nix    # Default NVIDIA provider
│   └── docs/
│       └── README.md         # This file
└── secrets/
    └── openclaw.yaml         # SOPS-encrypted secrets
```

---

## Configuration

### Options Reference

```nix
services.openclaw = {
  # Enable the service
  enable = true;
  
  # Package to use (defaults to pkgs.openclaw)
  package = pkgs.openclaw;
  
  # Workspace directory (sandboxed)
  workspace = "/var/lib/openclaw";
  
  # Network settings
  port = 18789;
  bindAddress = "127.0.0.1";  # localhost only for security
  
  # User/group
  user = "openclaw";
  group = "openclaw";
  
  # AI Provider
  defaultProvider = "nvidia";
  defaultModel = "nvidia/meta/llama-3.3-70b-instruct";
  
  # Tools
  tools.enable = true;
  tools.toolsPath = "/var/lib/openclaw/tools";
  
  # Debug mode (reduces hardening)
  debug = false;
  
  # Additional configuration (merged into openclaw.json)
  extraConfig = {
    # Custom settings
  };
  
  # Environment variables (non-secret)
  environment = {
    MY_VAR = "value";
  };
};
```

### Minimal Configuration

```nix
{
  services.openclaw.enable = true;
}
```

### Full Configuration Example

```nix
{
  services.openclaw = {
    enable = true;
    
    port = 18789;
    bindAddress = "127.0.0.1";
    
    defaultProvider = "nvidia";
    defaultModel = "nvidia/meta/llama-3.3-70b-instruct";
    
    extraConfig = {
      agents = {
        entries = {
          my-agent = {
            model = "nvidia/meta/llama-3.3-70b-instruct";
            systemPrompt = "You are a helpful assistant.";
          };
        };
      };
    };
  };
}
```

---

## Adding Providers

### Method 1: Copy the Template

```bash
cp OpenClaw/providers/_template.nix OpenClaw/providers/anthropic.nix
```

Edit the new file:

```nix
# OpenClaw/providers/anthropic.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.openclaw;
in {
  config = lib.mkIf cfg.enable {
    services.openclaw.extraConfig = {
      models = {
        providers = {
          anthropic = {
            type = "anthropic:api";
            apiKey = { "$ref" = "env.ANTHROPIC_API_KEY"; };
          };
        };
      };
    };
    
    services.openclaw.environment = {
      ANTHROPIC_API_KEY = lib.mkDefault "";
    };
  };
}
```

Add the key to `secrets/openclaw.yaml`:

```yaml
anthropic_api_key: sk-ant-xxx
```

### Method 2: In Your Configuration

```nix
# In your NixOS configuration
{
  services.openclaw = {
    enable = true;
    
    extraConfig = {
      models = {
        providers = {
          anthropic = {
            type = "anthropic:api";
            apiKey = { "$ref" = "env.ANTHROPIC_API_KEY"; };
          };
        };
        default = "anthropic/claude-sonnet-4-5";
      };
    };
    
    environment = {
      ANTHROPIC_API_KEY = "";  # Set via SOPS
    };
  };
}
```

### Supported Provider Types

| Type | Provider | Configuration |
|------|----------|---------------|
| `anthropic:api` | Anthropic Claude | `apiKey` required |
| `openai:default` | OpenAI GPT | `apiKey` required |
| `openai-compatible` | NVIDIA, OpenRouter, etc. | `baseUrl` + `apiKey` |
| `google:api` | Google Gemini | `apiKey` required |
| `deepseek:api` | DeepSeek | `apiKey` required |
| `ollama` | Local Ollama | `baseUrl` (no key needed) |

### Provider Examples

#### NVIDIA NIM (Default)

```nix
{
  type = "openai-compatible";
  baseUrl = "https://integrate.api.nvidia.com/v1";
  apiKey = { "$ref" = "env.NVIDIA_API_KEY"; };
  models = [
    "meta/llama-3.3-70b-instruct"
    "nvidia/llama-3.1-nemotron-70b-instruct"
  ];
}
```

Get API key: https://build.nvidia.com (free tier available)

#### Anthropic Claude

```nix
{
  type = "anthropic:api";
  apiKey = { "$ref" = "env.ANTHROPIC_API_KEY"; };
}
```

#### OpenAI

```nix
{
  type = "openai:default";
  apiKey = { "$ref" = "env.OPENAI_API_KEY"; };
}
```

#### Google Gemini

```nix
{
  type = "google:api";
  apiKey = { "$ref" = "env.GOOGLE_API_KEY"; };
}
```

#### OpenRouter

```nix
{
  type = "openai-compatible";
  baseUrl = "https://openrouter.ai/api/v1";
  apiKey = { "$ref" = "env.OPENROUTER_API_KEY"; };
  models = [
    "anthropic/claude-sonnet-4"
    "openai/gpt-4o"
    "google/gemini-pro-1.5"
  ];
}
```

#### Local Ollama

```nix
{
  type = "ollama";
  baseUrl = "http://localhost:11434";
  models = [
    "llama3.2"
    "codellama"
    "mistral"
  ];
}
```

---

## Creating Tools

Tools are shell scripts that run within the OpenClaw sandbox. They have access to:
- The workspace at `/var/lib/openclaw`
- Standard nixpkgs binaries
- Environment variables set by OpenClaw

They do NOT have access to:
- Files outside the workspace
- Network (unless explicitly configured)
- Root privileges

### Method 1: Manual Tool Creation

```bash
cp OpenClaw/tools/_template.nix OpenClaw/tools/my-tool.nix
```

Edit the tool:

```nix
# OpenClaw/tools/my-tool.nix
{ config, lib, pkgs, cfg }:

{
  name = "my-tool";
  description = "Does something useful";
  permissions = "0750";
  
  dependencies = with pkgs; [
    coreutils
    jq
  ];
  
  script = ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    WORKSPACE="${cfg.workspace}"
    
    # Your tool logic here
    echo '{"success": true}'
  '';
}
```

### Method 2: Using forge-tool

The `forge-tool` tool allows the AI agent to create new tools:

```bash
# In OpenClaw's workspace
forge-tool my-logger \
  'echo "$(date): $1" >> "$WORKSPACE/logs/app.log"' \
  --description="Log messages to app.log"
```

This creates a `.nix` file in `tools/.generated/` for user review.

### Tool Template Reference

```nix
{ config, lib, pkgs, cfg }:

{
  # Required: Tool name (alphanumeric, lowercase, dashes allowed)
  name = "tool-name";
  
  # Required: Human-readable description
  description = "What this tool does";
  
  # Optional: File permissions (default: 0750)
  permissions = "0750";
  
  # Optional: Packages from nixpkgs
  dependencies = with pkgs; [
    coreutils
    jq
    curl  # Only if network access is needed
  ];
  
  # Required: The shell script
  # Use ${cfg.workspace} to reference the workspace path
  script = ''
    #!/usr/bin/env bash
    # Standard header
    set -euo pipefail
    
    WORKSPACE="${cfg.workspace}"
    
    # Validate input
    if [[ -z "''${1:-}" ]]; then
      echo '{"error": "Missing argument"}'
      exit 1
    fi
    
    # Path validation function
    validate_path() {
      local path="$1"
      local resolved
      resolved="$(readlink -f "$path")"
      
      if [[ ! "$resolved" =~ ^"$WORKSPACE" ]]; then
        echo '{"error": "Path outside workspace"}'
        exit 2
      fi
      echo "$resolved"
    }
    
    # Main logic
    echo '{"success": true, "result": "..."}'
  '';
}
```

### Included Tools

| Tool | Description |
|------|-------------|
| `read-file` | Read files from workspace with encoding support |
| `write-file` | Write files to workspace with safety checks |
| `forge-tool` | Create new tool definitions |

---

## Security Hardening

This module implements comprehensive security hardening:

### SystemD Sandboxing

| Protection | Description |
|------------|-------------|
| `NoNewPrivileges` | Prevents privilege escalation |
| `PrivateTmp` | Isolated /tmp directory |
| `PrivateDevices` | No access to physical devices |
| `PrivateUsers` | User namespace isolation |
| `ProtectSystem=strict` | Read-only system directories |
| `ProtectHome` | No access to /home |
| `ProtectKernelTunables` | No access to kernel parameters |
| `ProtectKernelModules` | No access to kernel modules |
| `ProtectControlGroups` | No access to cgroups |
| `CapabilityBoundingSet=` | No capabilities |
| `SystemCallFilter` | Whitelist of allowed syscalls |
| `MemoryDenyWriteExecute` | No executable memory |
| `RestrictNamespaces` | No namespace creation |
| `RestrictAddressFamilies` | Only AF_INET, AF_INET6, AF_UNIX |

### Filesystem Sandbox

```
Allowed:
  /var/lib/openclaw          (workspace root)
  /var/lib/openclaw/workspace (file operations)
  /var/lib/openclaw/tools     (tool storage)
  /nix/store                  (read-only)

Denied:
  /home
  /root
  /etc/shadow, /etc/passwd
  /etc/ssh
  /var/lib/secrets
  /boot, /efi
```

### Network Security

- Gateway binds to `127.0.0.1` only by default
- Firewall rules block external access to gateway port
- Only outbound HTTPS to API endpoints allowed

### Debug Mode

For troubleshooting, you can temporarily reduce hardening:

```nix
{
  services.openclaw.debug = true;
}
```

**Warning**: Debug mode disables some protections. Do not use in production.

---

## SOPS Integration

### Secrets File Structure

Create `secrets/openclaw.yaml`:

```yaml
# Required for NVIDIA NIM (default provider)
nvidia_api_key: nvapi-xxx

# Optional: Other providers
anthropic_api_key: sk-ant-xxx
openai_api_key: sk-xxx
google_api_key: AIzaxxx
deepseek_api_key: sk-xxx
openrouter_api_key: sk-or-xxx

# Optional: Channel tokens
discord_bot_token: OTkx...
slack_bot_token: xoxb-...
telegram_bot_token: 123456:ABC...

# Gateway authentication
gateway_auth_token: your-secure-random-token-here
```

### Encrypt with SOPS

```bash
# Create .sops.yaml if not exists
cat > .sops.yaml << 'EOF'
keys:
  - &your-key age1xxx...
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
        - *your-key
EOF

# Encrypt
sops secrets/openclaw.yaml
```

### Adding New Secrets

1. Add to `secrets/openclaw.yaml`:
   ```yaml
   my_new_key: secret-value
   ```

2. Reference in configuration:
   ```nix
   {
     services.openclaw.extraConfig = {
       env = {
         MY_NEW_KEY = { "$ref" = "file:/var/lib/openclaw/.openclaw/secrets.yaml#/my_new_key"; };
       };
     };
   }
   ```

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u openclaw -f

# Check service status
systemctl status openclaw

# Verify configuration
cat /var/lib/openclaw/.openclaw/openclaw.json

# Check secrets
ls -la /var/lib/openclaw/.openclaw/
```

### API Key Not Working

```bash
# Verify secret is decrypted
sudo cat /var/lib/openclaw/.openclaw/secrets.yaml

# Check environment
sudo -u openclaw env | grep API_KEY
```

### Tool Permission Denied

```bash
# Check tool permissions
ls -la /var/lib/openclaw/tools/

# Verify ownership
stat /var/lib/openclaw/tools/your-tool
```

### Gateway Not Accessible

```bash
# Check if bound to localhost
ss -tlnp | grep 18789

# Test locally
curl http://127.0.0.1:18789/status

# Check firewall
iptables -L -n | grep 18789
```

### Reset Everything

```bash
# Stop service
systemctl stop openclaw

# Backup workspace
mv /var/lib/openclaw /var/lib/openclaw.backup

# Rebuild
sudo nixos-rebuild switch

# Restore specific files if needed
cp /var/lib/openclaw.backup/.openclaw/openclaw.json /var/lib/openclaw/.openclaw/
```

---

## Additional Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [NVIDIA NIM](https://build.nvidia.com)
- [ClawHub Skills Marketplace](https://clawdhub.com)
- [sops-nix](https://github.com/Mic92/sops-nix)

---

## License

This module is provided as-is for use with NixOS. OpenClaw itself has its own license terms.
