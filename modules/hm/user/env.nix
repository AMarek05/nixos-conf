{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.hmModules.user.env = {
    enable = lib.mkEnableOption "env";
  };

  config = lib.mkIf config.hmModules.user.env.enable {
    xdg.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    home.sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";

      EDITOR = "nvim";
      VISUAL = "nvim";

      QS_ICON_THEME = "Dracula";

      ANDROID_USER_HOME = "${config.xdg.dataHome}/android";

      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";

      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    };
  };
}
