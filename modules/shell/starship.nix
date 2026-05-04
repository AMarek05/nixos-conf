{ lib, config, ... }:

let
  dotsPath = ../../store;
in
{
  options.modules.shell.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = lib.mkIf config.modules.shell.starship.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };

    home.file = {
      ".config/starship.toml".source = dotsPath + /starship/starship.toml;
      # transient prompt sourced by zsh init — populate as desired
      ".config/.transient_prompt".source = dotsPath + /starship/.transient_prompt;
    };
  };
}
