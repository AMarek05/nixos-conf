{ config, lib, ... }:
{
  options.modules.links = {
    enable = lib.mkEnableOption "links";
  };

  config = lib.mkIf config.modules.links.enable {
    # starship.toml and .transient_prompt moved to terminal/starship.nix
  };
}