{ config, lib, ... }:
{
  options.modules.links = {
    enable = lib.mkEnableOption "links";
  };

  config = lib.mkIf config.modules.links.enable {
    home.file = {
      ".config/starship.toml".source = dots/starship/starship.toml;
      ".config/.transient_prompt".source = dots/starship/.transient_prompt;
      ".config/nvim".source = dots/nvim;
      "Scripts".source = dots/Scripts;
    };
  };
}
