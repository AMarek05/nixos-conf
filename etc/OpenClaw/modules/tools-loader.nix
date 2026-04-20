# OpenClaw Tools Auto-Loader
#
# This module automatically loads tool definitions from the tools/ subfolder.
# Each tool is evaluated and built as an immutable Nix store binary.
# These binaries are then explicitly added to the OpenClaw systemd service PATH.
#
# Also creates a symlink for TOOLS.md so the AI agent can understand
# its available capabilities.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;

  basePath = ../../OpenClaw;
  toolsPath = basePath + "/tools";

  # Function to load all tool files
  loadTool =
    file:
    import file {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    };

  # Get all tool files (excluding template and generated folders)
  toolFiles =
    let
      dir = toolsPath;
      files = builtins.attrNames (builtins.readDir dir);
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f) files;
    in
    map (f: dir + "/${f}") nixFiles;

  # Load all tools
  loadedTools = map loadTool toolFiles;

  generateToolDoc = tool: ''
    ### `${tool.name}`
    ${tool.description}

    **Usage:**
    `${tool.usage or "${tool.name} [arguments]"}`

    ${lib.optionalString ((builtins.hasAttr "arguments" tool) && (tool.arguments != [ ])) ''
      | Argument | Description | Default |
      |----------|-------------|---------|
      ${lib.concatMapStringsSep "\n" (
        a: "| `${a.name}` | ${a.desc} | `${a.default or "-"}` |"
      ) tool.arguments}
    ''}

    ${lib.optionalString ((builtins.hasAttr "examples" tool) && (tool.examples != [ ])) ''
      **Examples:**
      ${lib.concatMapStringsSep "\n" (ex: "* `${ex}`") tool.examples}
    ''}
    ---
  '';

  # Compile all tool docs into one string
  compiledToolsMarkdown = lib.concatMapStringsSep "\n" generateToolDoc loadedTools;

  # The final static wrapper text
  fullMarkdown = ''
    # OpenClaw Tool Capabilities & Workspace Guide

    You are an OpenClaw AI agent running in a highly secure, NixOS-based sandboxed environment. Your native `fs.read`, `fs.write`, and `shell` capabilities have been disabled for security. 

    To interact with the system, you must use the custom tools defined below via your `exec` capability. **Do not attempt to use shell pipes (`|`), redirections (`>`), or command chaining (`&&`).**

    ---

    ## Workspace Structure & Mandatory Workflow
    Your isolated environment is located at `/var/lib/openclaw`. You cannot read, write, or access files outside of this boundary.

    ### Mandatory Project Workflow
    1. **Project Isolation:** Every new task must be placed in its own dedicated subdirectory.
    2. **The TODO.md Requirement:** **Before** editing code, you MUST create a `TODO.md` file in the root of that project.
    3. **Continuous Updates:** Update the `TODO.md` file as work progresses to maintain your state.

    ---

    ## 🛠️ Core Tools

    ${compiledToolsMarkdown}

    ## 🛑 Critical System Constraints
    1. **Output Format:** All tools return strict JSON.
    2. **Path Constraints:** Tools run `realpath`. Using `../` to break out will result in `Access denied`.
    3. **Execution:** You do not have a shell. You must use the tools listed above via your native `exec`.
  '';

  generatedToolsDoc = pkgs.writeText "TOOLS.md" fullMarkdown;

  # Package each tool into an immutable Nix store binary
  # We wrap the script to ensure its specific dependencies are in its PATH
  toolPackages = map (
    tool:
    let
      innerScript = pkgs.writeScript "${tool.name}-inner" tool.script;
    in
    pkgs.writeShellScriptBin tool.name ''
      #!/usr/bin/env bash
      set -euo pipefail
      export OPENCLAW_TOOL="${tool.name}"
      export WORKSPACE="${cfg.workspace}"
      export PATH="${lib.makeBinPath (tool.dependencies or [ ])}:$PATH"

      # Safely execute the inner script with all arguments passed
      exec ${innerScript} "$@"
    ''
  ) loadedTools;

in
{
  config = lib.mkIf (cfg.enable && cfg.tools.enable) {

    # 1. Add tools directly to the OpenClaw service PATH
    # Systemd will expose all binaries in these packages to the service automatically
    systemd.services.openclaw.path = toolPackages;

    # 2. Add tools to the system environment (Optional, but highly recommended)
    # This allows you, the admin, to run tools like `list-dir` or `read-file`
    # directly from your terminal to test them.
    environment.systemPackages = toolPackages;

    # Explose to the module
    services.openclaw.tools.packages = toolPackages;

    # 3. Create symlink for TOOLS.md (agent capabilities documentation)
    systemd.services.openclaw.preStart = lib.mkBefore ''
      TOOLS_DOC_LINK="${cfg.workspace}/TOOLS.md"

      # Remove old symlink/file and link the freshly compiled Nix store document
      rm -f "$TOOLS_DOC_LINK"
      ln -sf "${generatedToolsDoc}" "$TOOLS_DOC_LINK"

      echo "Dynamically generated TOOLS.md symlinked to workspace."
    '';

    # Environment variables for tools and documentation
    systemd.services.openclaw.environment = {
      # Keep this pointing to the workspace tools dir so `forge-tool`
      # knows where to write new/pending tools for your review.
      OPENCLAW_TOOLS_PATH = cfg.tools.toolsStore;
      OPENCLAW_TOOLS_DOC = "${cfg.workspace}/TOOLS.md";
    };
  };
}
