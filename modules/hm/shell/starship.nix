{ lib, config, ... }:

let
  dotsPath = ../../../store;
in
{
  config = lib.mkIf config.hmModules.shell.starship.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };

    home.file = {
      # ".config/starship.toml".source = dotsPath + /starship/starship.toml;
      ".config/starship.toml".source = dotsPath + /starship/starship-jetpack.toml;

      ".config/.transient_prompt".source = dotsPath + /starship/.transient_prompt;
    };
  };
}
