# OpenClaw Hardened NixOS Module
#
# This is the main entry point for your flake. Simply add:
#   imports = [ ./openclaw.nix ];
# Or for flakes:
#   imports = [ "${self}/openclaw.nix" ];
#
# Structure:
#   openclaw.nix          <- This file (main entry point)
#   OpenClaw/
#     modules/
#       user.nix          <- User/group creation
#       systemd.nix       <- Hardened systemd service
#       sandbox.nix       <- Sandbox configuration
#       sops.nix          <- SOPS secrets integration
#       tools-loader.nix  <- Auto-loading tools mechanism
#     tools/
#       read-file.nix     <- Read files in workspace
#       write-file.nix    <- Write files in workspace
#       forge-tool.nix    <- Create new tools
#       _template.nix     <- Tool template for reference
#     providers/
#       nvidia-nim.nix    <- NVIDIA NIM default provider
#       _template.nix     <- Provider template
#     docs/
#       README.md         <- Documentation

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;

  # Determine the base path for the OpenClaw module
  basePath = ./OpenClaw;

  # Load all .nix files from a directory (excluding _template.nix)
  loadModules =
    dir:
    let
      files = builtins.attrNames (builtins.readDir dir);
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix") files;
    in
    map (f: dir + "/${f}") nixFiles;

  # Load provider modules
  providerModules = loadModules (basePath + "/providers");

in
{
  # Import all modular components
  imports = [
    (basePath + "/modules/user.nix")
    (basePath + "/modules/systemd.nix")
    (basePath + "/modules/sandbox.nix")
    (basePath + "/modules/sops.nix")
    (basePath + "/modules/tools-loader.nix")
  ]
  ++ providerModules;

  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw AI assistant gateway with hardened sandboxing";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openclaw;
      defaultText = lib.literalExpression "pkgs.openclaw";
      description = "The OpenClaw package to use.";
    };

    workspace = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openclaw";
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
      description = "Address to bind the gateway to. Default is localhost only for security.";
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

    # Provider configuration
    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "nvidia";
      description = "Default AI provider to use.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "nvidia/z-ai/glm-5.1";
      description = "Default model to use.";
    };

    # Additional configuration
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional OpenClaw configuration to merge.";
    };

    # Environment variables (for non-secret values)
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

    # Tools configuration
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

    # Debug mode (reduces hardening for troubleshooting)
    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug mode (reduces hardening).";
    };
  };

  config = {
    services.openclaw = {
      enable = true;

      sandboxedExecs.extraBins = {
        "jq" = pkgs.jq.bin;
        "rg" = pkgs.ripgrep;
        "find" = pkgs.findutils;
        "sed" = pkgs.gnused;
      };

      servicePath = with pkgs; [ bash ];
    };

    security.apparmor.enable = true;

    nixpkgs.config.permittedInsecurePackages = [
      "openclaw-2026.4.11"
    ];

    users.users.adam.extraGroups = [ cfg.group ];
    environment.systemPackages = with pkgs; [
      openclaw
      ollama-cuda
    ];
  };
}
