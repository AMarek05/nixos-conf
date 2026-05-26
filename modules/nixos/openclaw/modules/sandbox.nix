# OpenClaw Sandbox Configuration
#
# This module configures the sandbox environment for OpenClaw's tools,
# ensuring that file operations are restricted to the designated workspace.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openclaw;
  execCfg = cfg.sandboxedExecs;

  home = cfg.homedir or "/var/lib/openclaw";
  workspace = cfg.workspace or "/var/lib/openclaw/workspace";

  coreutilsBins = [
    # File Ops
    "ls"
    "cat"
    "cp"
    "mv"
    "rm"
    "mkdir"
    "touch"
    "tee"

    # Text Processing
    "head"
    "tail"
    "wc"
    "cut"
    "tr"
    "sort"
    "uniq"

    # Path Resolution
    "pwd"
    "basename"
    "dirname"
    "realpath"
    "readlink"
    "stat"

    # Scripting Helpers
    "echo"
    "printf"
    "test"
    "["
    "true"
    "false"
    "expr"
    "seq"
    "sleep"
    "date"
  ];

  # ── Bubblewrap wrapper builder ─────────────────────────────────────
  mkBwrapWrapper =
    name: package:
    let
      # Dynamically read from the configured options
      roDirs = [
        "/nix/store"
        "/etc"
        "/run/current-system"
        "/run/wrappers"
        "${home}"
      ]
      ++ execCfg.extraReadOnlyDirs;
      rwDirs = [
        workspace
        "/tmp"
        "/dev/null"
      ]
      ++ execCfg.extraReadWriteDirs;

      bwrapArgs = lib.concatStringsSep " \\\n    " (
        (map (dir: "--ro-bind ${dir} ${dir}") roDirs)
        ++ (map (dir: "--bind ${dir} ${dir}") rwDirs)
        ++ [
          "--proc /proc"
          "--dev /dev"

          "--tmpfs /tmp"
          "--tmpfs ${home}/.openclaw"

          "--unshare-user"
          "--unshare-ipc"

          "--die-with-parent"
          "--new-session"
        ]
        ++ lib.optional execCfg.allowNetwork "--share-net"
      );
    in
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.bubblewrap}/bin/bwrap \
        ${bwrapArgs} \
        ${lib.getExe' package name} "$@"
    '';

  # ── Wrapped packages ───────────────────────────────────────────────
  # Combined package
  sandboxedBins = pkgs.symlinkJoin {
    name = "openclaw-sandboxed-bins";
    paths =
      (map (name: mkBwrapWrapper name pkgs.coreutils) coreutilsBins)
      ++ (lib.mapAttrsToList (name: pkg: mkBwrapWrapper name pkg) execCfg.extraBins)
      ++ cfg.tools.packages;
  };
in
{
  # 1. DECLARE OPTIONS AT THE TOP LEVEL
  options.services.openclaw.sandboxedExecs = {
    enable = lib.mkEnableOption "Bubblewrap-wrapped coreutils for OpenClaw exec";

    allowNetwork = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to allow network access in wrapped binaries.";
    };

    extraReadWriteDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    extraReadOnlyDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    extraBins = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Extra package binaries to wrap. Attrset of name -> package.";
    };

    # THIS IS THE KEY ADDITION:
    # Expose the generated package so other modules can reference it.
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The combined package of all wrapped sandbox binaries.";
    };
  };

  # 2. DEFINE CONFIG
  config = lib.mkIf cfg.enable {
    # Assign the evaluated derivation to the option we just created
    services.openclaw.sandboxedExecs = {
      enable = true;
      package = sandboxedBins;
    };

    security.apparmor.policies = lib.mkIf config.security.apparmor.enable {
      openclaw = {
        state = "complain";

        profile = ''
          #include <tunables/global>

          # Point this directly at the launcher or the package binary
          ${lib.getExe cfg.package} flags=(attach_disconnected) {
            #include <abstractions/base>
            #include <abstractions/nameservice>

            # Allow the process to execute itself and its sub-processes
            # while keeping the environment (the 'n' flag is for Nix compatibility)
            file,
            capability,
            network,

            /nix/store/** rmix,
            
            # Allow the service to manage its own configuration
            ${home}/.openclaw/** rwl,
            ${home}/.openclaw/ rwl,

            # Full access to the rest of the workspace
            ${workspace}/** rwl,
            
            # Allow essential Node.js/V8 devices
            /dev/urandom r,
            /dev/null rw,
            /dev/zero rw,
            
            owner @{PROC}/@{pid}/maps r,
            owner @{PROC}/@{pid}/status r,

            signal (receive) set=("term"),
          }
        '';
      };
    };
  };
}
