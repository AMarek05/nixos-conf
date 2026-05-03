# ghostty module — GPU-terminal emulator configuration
{ config, lib, ... }:
{
  options.modules.terminal.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf config.modules.terminal.ghostty.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        theme = "TokyoNight Night";

        window-padding-x = 5;
        window-padding-y = 5;
        window-padding-balance = true;

        font-family = "JetBrainsMono Nerd Font";
        font-style = "JetBrainsMono NF Regular";

        app-notifications = false;
        shell-integration-features = "ssh-env,cursor,sudo,title";

        background-opacity = 0.92;
        background-blur = true;
      };
      enableZshIntegration = true;
    };
  };
}

