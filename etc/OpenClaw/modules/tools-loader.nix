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
  docsPath = basePath + "/TOOLS.md";

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
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix") files;
    in
    map (f: dir + "/${f}") nixFiles;

  # Load all tools
  loadedTools = map loadTool toolFiles;

  # Package each tool into an immutable Nix store binary
  # We wrap the script to ensure its specific dependencies are in its PATH
  toolPackages = map (
    tool:
    pkgs.writeShellScriptBin tool.name ''
      # Inject tool-specific dependencies into the PATH
      export PATH="${lib.makeBinPath (tool.dependencies or [ ])}:$PATH"

      # Execute the original tool script
      ${tool.script}
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

    # 3. Create symlink for TOOLS.md (agent capabilities documentation)
    systemd.services.openclaw.preStart = lib.mkBefore ''
      TOOLS_DOC="${docsPath}"
      TOOLS_DOC_LINK="${cfg.workspace}/TOOLS.md"

      if [[ -f "$TOOLS_DOC" ]]; then
        # Remove existing link/file if present
        rm -f "$TOOLS_DOC_LINK"
        # Create symlink pointing to the flake's TOOLS.md
        ln -sf "$TOOLS_DOC" "$TOOLS_DOC_LINK"

        echo "TOOLS.md symlinked to $TOOLS_DOC"
      else
        echo "Warning: TOOLS.md not found at $TOOLS_DOC"
      fi
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
