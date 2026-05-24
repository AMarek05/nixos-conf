# OpenClaw Hardened NixOS Module
#
# Self-contained under modules/nixos/openclaw/.
#
# Enabled via: nixosModules.openclaw.enable = true (default: false)
# When enabled, configures services.openclaw.* as the service interface.
# All .nix files in modules/ and tools/ are auto-sourced.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;

  # basePath is relative to this file (modules/nixos/openclaw/default.nix)
  basePath = ./.;

  # Auto-source all .nix files in a directory (excluding _template.nix)
  autoImportDir =
    dir:
    let
      files = builtins.attrNames (builtins.readDir dir);
      nixFiles = lib.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix") files;
    in
    map (f: dir + "/${f}") nixFiles;

  # Recursively collect all tool .nix files
  toolFiles =
    let
      toolsDir = basePath + "/tools";
      files = builtins.attrNames (builtins.readDir toolsDir);
      nixFiles = lib.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix" && f != "TODO.md") files;
    in
    map (f: toolsDir + "/${f}") nixFiles;

  # Load all tool definitions (used by tools-loader.nix)
  loadedTools = map (f: import f { inherit config lib pkgs cfg; }) toolFiles;

in
{
  # Enable/disable via nixosModules.openclaw.enable
  options.nixosModules.openclaw.enable = lib.mkEnableOption "OpenClaw AI assistant";

  # Auto-source all sub-modules in modules/
  imports = autoImportDir (basePath + "/modules");

  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw service (auto-enabled when nixosModules.openclaw.enable is true)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openclaw;
      defaultText = lib.literalExpression "pkgs.openclaw";
      description = "The OpenClaw package to use.";
    };

    homedir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openclaw";
      description = "The OpenClaw user home directory";
    };

    workspace = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.homedir}/workspace";
      description = "The sandboxed workspace directory for OpenClaw.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Port for the OpenClaw gateway.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the gateway to.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "User to run OpenClaw as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "Group for OpenClaw.";
    };

    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "nvidia";
      description = "Default AI provider to use.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Default model to use.";
    };

    modelAlias = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The alias to use for the default model.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional OpenClaw configuration to merge.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables to set for OpenClaw.";
    };

    servicePath = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ cfg.sandboxedExecs.package ];
      description = "List of packages to be appended to the path and accessible to the systemd service";
    };

    tools = {
      enable = lib.mkEnableOption "the OpenClaw tool system" // {
        default = true;
      };

      toolsStore = lib.mkOption {
        type = lib.types.path;
        default = cfg.workspace + "/tools";
        description = "Path where pending tools are stored.";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Custom-built packages for and by the agent";
      };
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug mode (reduces hardening).";
    };
  };

  config = lib.mkIf config.nixosModules.openclaw.enable {
    services.openclaw = {
      enable = true;

      defaultModel = "minimax/MiniMax-M2.7";
      defaultProvider = "minimax";
      modelAlias = "Minimax";

      sandboxedExecs.extraBins = {
        "jq" = pkgs.jq.bin;
        "rg" = pkgs.ripgrep;
        "sed" = pkgs.gnused;
        "xxd" = pkgs.xxd;
        "patch" = pkgs.patch;
      };

      servicePath = with pkgs; [ bash ];
    };

    security.apparmor.enable = true;

    nixpkgs.config.allowInsecurePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "openclaw"
      ];

    users.users.adam.extraGroups = [ cfg.group ];
    environment.systemPackages = with pkgs; [
      openclaw
    ];
  };
}