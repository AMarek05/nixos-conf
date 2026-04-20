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
  execCfg = cfg.sandboxedExecss;

  workspace = cfg.workspace or "/var/lib/openclaw";

  coreutilsBins = builtins.attrNames (builtins.readDir "${pkgs.coreutils}/bin");

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
        "${workspace}/.openclaw"
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
          "--unshare-all"
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
      ++ (lib.mapAttrsToList (name: pkg: mkBwrapWrapper name pkg) execCfg.extraBins);
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
        state = "enforce";

        profile = ''
          ${lib.getExe cfg.package} {
            # Basic capabilities
            capability dac_read_search,
            capability dac_override,


            # Network access for API calls
            network inet stream,
            network inet6 stream,
            network unix stream,


            # Read access to system files
            /etc/resolv.conf r,
            /etc/hosts r,
            /etc/nsswitch.conf r,
            /etc/ssl/certs/** r,
            /nix/store/** r,

            # Full access to workspace
            ${cfg.workspace}/** rwl,
            ${cfg.workspace}/workspace/** rwl,
            ${cfg.workspace}/tools/** rwl,

            # Deny everything else
            deny /** rwlx,
            deny /proc/** rwlx,
            deny /sys/** rwlx,
          }
        '';
      };
    };
  };
}
