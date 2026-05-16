{ config, lib, ... }:
let
  cfg = config.modules.terminal.ghostty;
in
{
  options.modules.terminal.ghostty = {
    enable = lib.mkEnableOption "Add ghostty installation and configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        # theme = "TokyoNight Night";
        theme = "Catppuccin Mocha";

        window-padding-x = 5;
        window-padding-y = 5;
        window-padding-balance = true;

        clipboard-read = "allow";

        font-family = "0xProto Nerd Font";

        app-notifications = false;
        shell-integration-features = "ssh-env,cursor,sudo,title";

        background-opacity = 0.92;
        background-blur = true;
      };
      enableZshIntegration = true;
    };
  };
}
