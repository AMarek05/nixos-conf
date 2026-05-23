# OpenClaw Hardened NixOS Module
#
# Main entry point — imports all sub-modules and defines the services.openclaw
# option set. Self-contained under modules/nixos/openclaw/.
#
# Usage in a host config:
#   imports = [ ./openclaw.nix ];   # or: modules.nixos.openclaw.enable = true;

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

  loadModules =
    dir:
    let
      files = builtins.attrNames (builtins.readDir dir);
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && f != "_template.nix") files;
    in
    map (f: dir + "/${f}") nixFiles;

in
{
  imports = [
    (basePath + "/modules/user.nix")
    (basePath + "/modules/systemd.nix")
    (basePath + "/modules/sandbox.nix")
    (basePath + "/modules/sops.nix")
    (basePath + "/modules/tools-loader.nix")
  ];

  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw AI assistant gateway with hardened sandboxing";

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

  config = {
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