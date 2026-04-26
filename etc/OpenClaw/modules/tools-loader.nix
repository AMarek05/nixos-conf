# OpenClaw Tools Auto-Loader
#
# This module automatically loads tool definitions from the tools/ subfolder.
# Each tool is evaluated and built as an immutable Nix store binary.
# These binaries are then explicitly added to the OpenClaw systemd service PATH.
#
# Also creates a symlink for TOOLS.md so the AI agent can understand
# its available capabilities.
#
# Additionally generates skills in ~/.openclaw/skills/ for the skill-based
# tool execution system.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
  sandbox = cfg.sandboxedExecs;

  basePath = ../../OpenClaw;
  toolsPath = basePath + "/tools";
  skillsDir = "${cfg.homedir}/.openclaw/skills";

  # List of executables
  binNames = builtins.attrNames (builtins.readDir "${sandbox.package}/bin/");

  formattedBinNames = lib.concatMapStringsSep ", " (name: "\`${name}\`") binNames;

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
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix" && f != "TODO.md") files;
    in
    map (f: dir + "/${f}") nixFiles;

  # Load all tools
  loadedTools = map loadTool toolFiles;

  # Generate SKILL.md content for a tool
  generateSkillMd = tool:
    let
      argsStr = lib.concatMapStringsSep "\n" (a: ''
        - `${a.name}` - ${a.desc} (default: `${a.default or "-"}`)'') (tool.arguments or []);
      examplesStr = lib.concatMapStringsSep "\n" (e: ''- `${e}`'') (tool.examples or []);
      depsStr = lib.concatMapStringsSep ", " (d: "`${d}`") (tool.dependencies or []);
    in
    ''
    ---
    name: ${tool.name}
    description: ${tool.description}
    metadata:
      openclaw:
        tools:
          - name: ${tool.name}
            description: ${tool.description}
            arguments:
              ${lib.optionalString ((tool.arguments or []) != [ ]) argsStr}
    ---

    # ${tool.name}

    ${tool.description}

    ## Usage

    ```
    ${tool.usage or tool.name}
    ```

    ${lib.optionalString ((tool.arguments or []) != [ ]) ''
    ## Arguments

    ${argsStr}
    ''}

    ${lib.optionalString (tool ? examples && tool.examples != [ ]) ''
    ## Examples

    ${examplesStr}
    ''}

    ## Dependencies

    ${depsStr}
    '';

  # Generate tool documentation for TOOLS.md
  generateToolDoc = tool:
    let
      argsTable = lib.optionalString ((builtins.hasAttr "arguments" tool) && (tool.arguments != [ ])) ''
        | Argument | Description | Default |
        |----------|-------------|---------|
        ${lib.concatMapStringsSep "\n" (
          a: "| `${a.name}` | ${a.desc} | `${a.default or "-"}` |"
        ) tool.arguments}
      '';
      examplesBlock = lib.optionalString ((builtins.hasAttr "examples" tool) && (tool.examples != [ ])) ''
        **Examples:**
        ${lib.concatMapStringsSep "\n" (ex: "* `${ex}`") tool.examples}
      '';
    in
    ''
    ### `${tool.name}`
    ${tool.description}

    **Usage:**
    ``${tool.usage or "${tool.name} [arguments]"}``

    ${argsTable}
    ${examplesBlock}
    ---
  '';

  # Generate the tools markdown for all tools (used in TOOLS.md)
  compiledToolsMarkdown = lib.concatMapStringsSep "\n" generateToolDoc loadedTools;

  # The final static wrapper text (original TOOLS.md format)
  fullMarkdown = ''
    # OpenClaw Tool Capabilities & Workspace Guide

    You are an OpenClaw AI agent running in a highly secure, NixOS-based sandboxed environment. Your native `fs.read`, `fs.write`, and `shell` capabilities have been disabled for security. 

    To interact with the system, you must use the custom tools defined below via your `exec` capability. **Do not attempt to use shell pipes (`|`), redirections (`>`), or command chaining (`&&`). They will require approval.**

    ! Do NOT redirect stderr to stdout ! Doing so triggers an unnecessary approval prompt, both stdout and stderr are displayed side by side by default anyways.

    Your allowed executables include: [ ${formattedBinNames} ]

    All of these are overwritten to only work in your workspace. If at any point you are confused about the usage, refer to this file, to the docs below.

    ---

    ## Workspace Structure & Mandatory Workflow
    Your isolated environment is located at `/var/lib/openclaw`. You cannot read, write, or access files outside of this boundary.

    ### Mandatory Project Workflow
    1. **Project Isolation:** Every new task must be placed in its own dedicated subdirectory.
    2. **The TODO.md Requirement:** **Before** editing code, you MUST create a `TODO.md` file in the root of that project.
    3. **Continuous Updates:** Update the `TODO.md` file as work progresses to maintain your state.

    ---

    ## Core Tools

    ${compiledToolsMarkdown}

    ## Critical System Constraints
    1. **Output Format:** All tools return strict JSON.
    2. **Path Constraints:** Tools run `realpath`. Using `../` to break out will result in `Access denied`. Accessing ~/.openclaw is disallowed, it contains secrets and configs.
    3. **Execution:** You do not have a shell. You must use the tools listed above via your native `exec`.
    4. **exec limitation:** Each exec of an executable not on the above lists will need approval. Prioritise them as much as possible.
    5. **Permissions:** When creating files, ensure the same file permissions for yourself and for your group. It will allow me easy access to the files.
  '';

  # Generate SKILL.md for each tool
  skillDocs = lib.listToAttrs (
      map (tool: lib.nameValuePair tool.name (pkgs.writeText "${tool.name}-SKILL.md" (generateSkillMd tool)))
      loadedTools
  );

  # Generate the TOOLS.md file
  generatedToolsDoc = pkgs.writeText "TOOLS.md" fullMarkdown;

  # Helper to get script content from a tool
  getScriptContent = tool:
    if builtins.isPath tool.script then
      builtins.readFile tool.script
    else
      tool.script;

  # Filter tools that can't be converted to skills
  # old-write requires Nix compilation step, so skip it
  toolsNeedingNix = [ "old-write" ];
  canBeSkill = tool: !(builtins.elem tool.name toolsNeedingNix);

  # Create skill packages (directory with SKILL.md + scripts/)
  skillPackages = map (
    tool:
    let
      scriptContent = getScriptContent tool;
      scriptName = if builtins.isPath tool.script then
        (builtins.baseNameOf tool.script)
      else
        "${tool.name}.sh";
      skillDoc = skillDocs.${tool.name};
    in
    pkgs.runCommand "skill-${tool.name}" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      mkdir -p $out/${tool.name}/scripts
      cp ${skillDoc} $out/${tool.name}/SKILL.md
      ${lib.optionalString (builtins.isPath tool.script) ''
        cp ${tool.script} $out/${tool.name}/scripts/${scriptName}
        chmod +x $out/${tool.name}/scripts/${scriptName}
      ''}
      ${lib.optionalString (!builtins.isPath tool.script) ''
        echo '#!/usr/bin/env bash' > $out/${tool.name}/scripts/${scriptName}
        echo '${lib.replaceStrings ["'" "\\"] ["'\\''" "''"] scriptContent}' >> $out/${tool.name}/scripts/${scriptName}
        chmod +x $out/${tool.name}/scripts/${scriptName}
      ''}
    ''
  ) (builtins.filter canBeSkill loadedTools);

  # Combined skill package
  allSkills = pkgs.symlinkJoin {
    name = "openclaw-skills";
    paths = skillPackages;
  };

  toolPackages = map (
    rawTool:
    let
      helpFlag = {
        name = "--help|-h";
        desc = "Show this help message";
        default = "false";
      };
      enhancedArgs = (rawTool.arguments or [ ]) ++ [ helpFlag ];
      tool = rawTool // {
        arguments = enhancedArgs;
      };
      innerScript =
        if builtins.isPath tool.script then
          tool.script
        else
          pkgs.writeShellScript "${tool.name}-inner" tool.script;
      scriptPath = tool.dependencies ++ cfg.servicePath;
      helpText = ''
        ${tool.name} - ${tool.description or "No description provided."}

        USAGE:
          ${tool.usage or "${tool.name} [args...]"}
        ${lib.optionalString (builtins.length tool.arguments > 0) ''

          ARGUMENTS:
          ${lib.concatMapStringsSep "\n" (
            a: "  ${a.name}\n      Description: ${a.desc}\n      Default: ${a.default}"
          ) tool.arguments}''}
        ${lib.optionalString (tool ? examples && builtins.length tool.examples > 0) ''

          EXAMPLES:
          ${lib.concatMapStringsSep "\n" (e: "  ${e}") tool.examples}''}
      '';
    in
    pkgs.writeShellScriptBin tool.name ''
      set -euo pipefail

      if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
        cat << 'EOF'
      ${helpText}
      EOF
        exit 0
      fi

      export OPENCLAW_TOOL="${tool.name}"
      export WORKSPACE="${cfg.workspace}"
      export PATH="${lib.makeBinPath scriptPath}"

      exec ${innerScript} "$@"
    ''
  ) loadedTools;

in
{
  config = lib.mkIf (cfg.enable && cfg.tools.enable) {
    environment.systemPackages = toolPackages;

    services.openclaw.tools.packages = toolPackages;

    systemd.services.openclaw.preStart = lib.mkBefore ''
      TOOLS_DOC="${cfg.workspace}/TOOLS.md"
      SKILLS_DIR="${cfg.homedir}/.openclaw/skills"

      # Remove old symlink/file and link the freshly compiled Nix store document
      ${pkgs.coreutils}/bin/rm -f "$TOOLS_DOC"
      ${pkgs.coreutils}/bin/cp "${generatedToolsDoc}" "$TOOLS_DOC" || exit 1

      # Install skills to ~/.openclaw/skills/
      ${pkgs.coreutils}/bin/rm -rf "$SKILLS_DIR"
      ${pkgs.coreutils}/bin/mkdir -p "$SKILLS_DIR"
      ${pkgs.coreutils}/bin/cp -r ${allSkills}/. "$SKILLS_DIR/"

      echo "Dynamically generated TOOLS.md copied to workspace."
      echo "Skills installed to $SKILLS_DIR"
    '';

    # Environment variables for tools and documentation
    systemd.services.openclaw.environment = {
      OPENCLAW_TOOLS_PATH = cfg.tools.toolsStore;
      OPENCLAW_TOOLS_DOC = "${cfg.workspace}/TOOLS.md";
      OPENCLAW_SKILLS_DIR = "$SKILLS_DIR";
    };
  };
}