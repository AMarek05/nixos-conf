{ config, lib, ... }:
let
  dotsPath = ../store;
in
{
  options.modules.links = {
    enable = lib.mkEnableOption "links";
  };

  config = lib.mkIf config.modules.links.enable {
    home.file = {
      ".config/starship.toml".source = /. + dotsPath + "/starship/starship.toml";
      ".config/.transient_prompt".source = /. + dotsPath + "/starship/.transient_prompt";
      # ".config/nvim".source = /. + dotsPath + "/nvim";
      "Scripts".source = /. + dotsPath + "/Scripts";
    };
  };
}
