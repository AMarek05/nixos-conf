{ config, lib, ... }:
{
  options.hmModules.links = {
    enable = lib.mkEnableOption "links";
  };

  config = lib.mkIf config.hmModules.links.enable {
    # starship.toml and .transient_prompt moved to terminal/starship.nix
  };
}