{
  config,
  lib,
  myLib,
  ...
}:
let
  cfg = config.hmModules.hyprland;

  inherit (myLib) toLua;
  inherit (lib) mkOption types concatMapStringsSep;

  renderMonitor = mon: "hl.monitor(${toLua mon})";
in
{
  options.hmModules.hyprland = {
    monitors = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "List of monitor configs passed to hl.monitor()";
      example = lib.literalExpression ''
        [
          {output = "DP-1"; mode = "1920x1080@144"; position = "0x0"; scale = 1; };
          { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
        ];
      '';
    };
  };

  config = {
    hmModules.hyprland.settings = {
      general = {
        gaps_in = 5;
        gaps_out = 15;
        border_size = 2;
      };

      dwindle = {
        preserve_split = true;
        smart_split = false;
        smart_resizing = false;
      };

      decoration = {
        rounding = 6;
        rounding_power = 3;
      };
    };

    wayland.windowManager.hyprland.extraConfig = ''
      -- Monitors
      ${concatMapStringsSep "\n" renderMonitor cfg.monitors}
    '';
  };
}
