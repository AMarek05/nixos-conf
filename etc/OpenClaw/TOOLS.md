# OpenClaw Tool Capabilities

This document describes the tools available to OpenClaw AI agents. Tools are shell scripts that run within a sandboxed workspace at `/var/lib/openclaw`. All file operations are restricted to this workspace for security.

## Workspace Structure

```
/var/lib/openclaw/
├── workspace/          # Your working directory for file operations
├── tools/              # Available tools (executables)
├── tools/.generated/   # Agent-generated tools pending review
├── logs/               # Log files
└── .openclaw/          # OpenClaw configuration (read-only)
```

---

## Core Tools

### read-file

Read a file from the workspace with encoding support.

**Usage:**
```bash
read-file <path> [--lines=N] [--offset=N] [--encoding=ENC]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Relative or absolute path to file (required) | - |
| `--lines=N` | Read only N lines | 1000 |
| `--offset=N` | Start from line N (requires --lines) | 0 |
| `--encoding=ENC` | Force encoding: `utf-8`, `base64`, `hex`, `auto` | auto |

**Output:** JSON object with file contents and metadata

**Examples:**
```bash
# Read a text file
read-file workspace/myfile.txt

# Read first 50 lines
read-file workspace/data.json --lines=50

# Read lines 100-150
read-file workspace/large.log --lines=50 --offset=100

# Read binary file as base64
read-file workspace/image.png --encoding=base64
```

**Output Format:**
```json
{
  "success": true,
  "path": "/var/lib/openclaw/workspace/myfile.txt",
  "relative_path": "workspace/myfile.txt",
  "mime_type": "text/plain",
  "encoding": "text",
  "size_bytes": 1234,
  "total_lines": 100,
  "lines_read": 50,
  "offset": 0,
  "content": "file contents here..."
}
```

**Error Responses:**
- `{"error": "File not found: ..."}` - Path doesn't exist
- `{"error": "Access denied: path outside workspace"}` - Security violation
- `{"error": "File too large: ..."}` - Exceeds 10MB limit

---

### write-file

Write content to a file in the workspace.

**Usage:**
```bash
write-file <path> <content> [options]
write-file <path> --stdin [options]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Relative or absolute path to file (required) | - |
| `content` | Content to write (or use `--stdin`) | - |
| `--stdin` | Read content from stdin | false |
| `--encoding=ENC` | Content encoding: `text`, `base64`, `hex` | text |
| `--append` | Append to file instead of overwriting | false |
| `--mode=MODE` | File permissions (octal) | 0644 |
| `--mkdir` | Create parent directories if needed | false |

**Output:** JSON object with result

**Examples:**
```bash
# Write a text file
write-file workspace/hello.txt "Hello, World!"

# Write JSON content
write-file workspace/data.json '{"key": "value"}'

# Write binary data (base64 encoded)
write-file workspace/binary.bin "SGVsbG8=" --encoding=base64

# Append to existing file
write-file workspace/log.txt "New log entry\n" --append

# Create with specific permissions
write-file workspace/script.sh "#!/bin/bash" --mode=0755

# Create nested directory and file
write-file workspace/deep/nested/file.txt "content" --mkdir

# Pipe content
echo "Dynamic content" | write-file workspace/output.txt --stdin
```

**Output Format:**
```json
{
  "success": true,
  "path": "/var/lib/openclaw/workspace/hello.txt",
  "relative_path": "workspace/hello.txt",
  "operation": "created",
  "encoding": "text",
  "size_bytes": 13,
  "mode": "644"
}
```

**Operations:**
- `created` - New file created
- `overwritten` - Existing file replaced
- `appended` - Content added to end

---

### list-dir

List directory contents with optional recursion.

**Usage:**
```bash
list-dir [path] [options]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Directory to list | workspace root |
| `--recursive`, `-r` | List subdirectories | false |
| `--hidden`, `-a` | Show hidden files | false |
| `--long`, `-l` | Show detailed info | false |

**Output:** JSON object with entries array

**Examples:**
```bash
# List workspace root
list-dir

# List specific directory
list-dir workspace/projects

# Recursive listing
list-dir workspace --recursive

# Detailed listing with hidden files
list-dir workspace --long --hidden

# Full recursive scan
list-dir --recursive --long
```

**Output Format:**
```json
{
  "success": true,
  "path": "/var/lib/openclaw/workspace",
  "relative_path": "/",
  "recursive": false,
  "entries": [
    {"name": "file.txt", "type": "file"},
    {"name": "subdir", "type": "directory"},
    {"name": "link", "type": "symlink"}
  ]
}
```

**With `--long`:**
```json
{
  "entries": [
    {
      "name": "file.txt",
      "type": "file",
      "size": 1234,
      "mtime": 1704067200,
      "mode": "644"
    }
  ]
}
```

---

### delete-file

Delete files or directories from the workspace.

**Usage:**
```bash
delete-file <path> [options]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Path to delete (required) | - |
| `--recursive`, `-r` | Required for directories | false |
| `--force`, `-f` | Skip confirmation | false |

**Output:** JSON object with deletion details

**Examples:**
```bash
# Delete a file
delete-file workspace/old-file.txt

# Delete a directory (requires --recursive)
delete-file workspace/old-folder --recursive

# Force deletion
delete-file workspace/unwanted --recursive --force
```

**Output Format:**
```json
{
  "success": true,
  "deleted_path": "/var/lib/openclaw/workspace/old-file.txt",
  "relative_path": "workspace/old-file.txt",
  "type": "file",
  "files_removed": 1,
  "bytes_freed": 1234
}
```

**Protected Paths (cannot be deleted):**
- `/var/lib/openclaw` (workspace root)
- `/var/lib/openclaw/.openclaw` (configuration)
- `/var/lib/openclaw/tools` (tools directory)
- `/var/lib/openclaw/workspace` (workspace directory)

---

### search-files

Search for files by name or content within the workspace.

**Usage:**
```bash
search-files <pattern> [options]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `pattern` | Search pattern (regex supported) | required |
| `--path=DIR` | Directory to search | workspace |
| `--type=TYPE` | Filter by type: `file`, `dir`, `symlink` | all |
| `--max-results=N` | Maximum results | 100 |
| `--content`, `-c` | Search file contents | false |
| `--case-sensitive`, `-s` | Case-sensitive search | false |

**Output:** JSON object with results array

**Examples:**
```bash
# Find all .txt files
search-files "\.txt$"

# Find files containing "error"
search-files "error" --content

# Search in specific directory
search-files "TODO" --content --path=workspace/src

# Case-sensitive filename search
search-files "Config" --case-sensitive

# Limit results
search-files "function" --content --max-results=20
```

**Filename Search Output:**
```json
{
  "success": true,
  "pattern": "\\.txt$",
  "search_path": "/var/lib/openclaw/workspace",
  "search_type": "filename",
  "results_count": 3,
  "max_results": 100,
  "results": [
    {"path": "/var/lib/openclaw/workspace/file.txt", "relative_path": "file.txt", "type": "file"},
    {"path": "/var/lib/openclaw/workspace/notes.txt", "relative_path": "notes.txt", "type": "file"}
  ]
}
```

**Content Search Output:**
```json
{
  "success": true,
  "pattern": "error",
  "search_type": "content",
  "results": [
    {"path": "/var/lib/openclaw/workspace/app.log", "line": 42, "content": "ERROR: Connection failed"}
  ]
}
```

---

### forge-tool

Create a new tool definition that can be reviewed and deployed.

**Usage:**
```bash
forge-tool <name> <script> [options]
```

**Arguments:**
| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Tool name (lowercase, alphanumeric, dashes) | required |
| `script` | Shell script content | required |
| `--description=DESC` | Human-readable description | - |
| `--dependencies=DEPS` | Comma-separated nixpkgs packages | - |
| `--script-file=PATH` | Read script from file | - |
| `--auto-approve` | Auto-approve tool (caution!) | false |
| `--review` | Mark for user review (default) | true |

**Output:** JSON with tool path and instructions

**Examples:**
```bash
# Create a simple logging tool
forge-tool my-logger \
  'echo "$(date): $1" >> "$WORKSPACE/logs/custom.log"' \
  --description="Log messages to custom.log"

# Create tool with dependencies
forge-tool json-format \
  'cat "$1" | jq .' \
  --description="Format JSON files" \
  --dependencies="jq"

# Create from script file
forge-tool complex-tool --script-file=/tmp/my-script.sh

# Auto-approve (use with caution)
forge-tool simple-calc 'echo $(($1 + $2))' --auto-approve
```

**Output Format:**
```json
{
  "success": true,
  "tool_name": "my-logger",
  "description": "Log messages to custom.log",
  "status": "pending_review",
  "nix_file": "/var/lib/openclaw/tools/.generated/my-logger.nix",
  "symlink": null,
  "instructions": {
    "review": "Review the generated file at: /var/lib/openclaw/tools/.generated/my-logger.nix",
    "approve": "Move to flake tools directory: cp /var/lib/openclaw/tools/.generated/my-logger.nix /path/to/flake/OpenClaw/tools/",
    "reject": "Delete the file: rm /var/lib/openclaw/tools/.generated/my-logger.nix",
    "list_pending": "ls /var/lib/openclaw/tools/.generated/*.nix"
  }
}
```

**Tool Naming Rules:**
- Must start with a lowercase letter
- Can contain lowercase letters, numbers, and dashes
- Cannot start with underscore (reserved for templates)

**Generated Tool Structure:**
```nix
# Auto-generated by forge-tool
{ config, lib, pkgs, cfg }:

{
  name = "my-logger";
  description = "Log messages to custom.log";
  permissions = "0750";
  dependencies = with pkgs [ ];
  script = ''
    #!/usr/bin/env bash
    set -euo pipefail
    WORKSPACE="${cfg.workspace}"
    # ... your script ...
  '';
}
```

---

## Tool Development

### Creating Custom Tools

Custom tools are `.nix` files placed in `OpenClaw/tools/`. Each tool defines:

```nix
# OpenClaw/tools/my-tool.nix
{ config, lib, pkgs, cfg }:

{
  # Required: Tool name
  name = "my-tool";
  
  # Required: Description
  description = "What this tool does";
  
  # Optional: File permissions
  permissions = "0750";
  
  # Optional: nixpkgs dependencies
  dependencies = with pkgs; [
    coreutils
    jq
  ];
  
  # Required: Shell script
  script = ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Workspace path available as $WORKSPACE
    WORKSPACE="${cfg.workspace}"
    
    # Always validate paths before file operations
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
    
    # Return JSON output
    echo '{"success": true, "result": "..."}'
  '';
}
```

### Best Practices

1. **Always validate paths** - Use the `validate_path` function pattern
2. **Return JSON** - All output should be valid JSON for parsing
3. **Use exit codes** - 0 for success, 1 for user errors, 2 for system errors
4. **Handle errors gracefully** - Catch errors and return meaningful messages
5. **Document usage** - Include comments with usage examples
6. **Keep it simple** - One tool, one purpose

### Available Variables

| Variable | Description |
|----------|-------------|
| `$WORKSPACE` | Path to `/var/lib/openclaw` |
| `$PATH` | Includes nixpkgs binaries from dependencies |

### Security Constraints

Tools cannot:
- Access files outside `/var/lib/openclaw`
- Execute arbitrary commands outside the tool script
- Access network (unless explicitly configured)
- Modify system configuration
- Access other users' files

---

## Error Handling

All tools return JSON with consistent error format:

```json
{
  "error": "Description of what went wrong"
}
```

**Common Error Types:**

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `Missing required argument: ...` | Required argument not provided | Check usage and provide the argument |
| `File not found: ...` | Path doesn't exist | Verify path with `list-dir` |
| `Access denied: path outside workspace` | Attempted to access restricted path | Use paths within workspace only |
| `File too large: ...` | Exceeds size limit (10MB) | Read in chunks with `--lines` |
| `Cannot delete protected path` | Attempted to delete protected directory | Choose a different target |
| `Directory not found` | Parent directory doesn't exist | Create with `--mkdir` or create manually |
| `Unknown option: ...` | Invalid flag provided | Check usage for valid options |

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User error (invalid input, not found) |
| 2 | System error (permission denied, outside workspace) |

---

## Quick Reference

| Task | Command |
|------|---------|
| Read a file | `read-file workspace/file.txt` |
| Write a file | `write-file workspace/file.txt "content"` |
| List directory | `list-dir workspace` |
| Delete file | `delete-file workspace/file.txt` |
| Delete directory | `delete-file workspace/dir --recursive` |
| Search filenames | `search-files "\.txt$"` |
| Search content | `search-files "error" --content` |
| Create tool | `forge-tool name 'script' --description="..."` |

---

## Workspace Paths

When referencing paths, you can use:

- **Relative paths**: `workspace/file.txt` (relative to workspace root)
- **Absolute paths**: `/var/lib/openclaw/workspace/file.txt`

Both are valid. The tools will automatically resolve and validate paths.

**Recommended structure:**
```
/var/lib/openclaw/
├── workspace/
│   ├── projects/    # Your projects
│   ├── data/        # Data files
│   ├── logs/        # Log files
│   └── temp/        # Temporary files
└── tools/           # Available tools
```
