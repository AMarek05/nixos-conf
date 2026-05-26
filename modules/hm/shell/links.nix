{ config, lib, ... }:
{
  options.hmModules.shell.links = {
    enable = lib.mkEnableOption "links";
  };

  config = lib.mkIf config.hmModules.shell.links.enable {
    # starship.toml and .transient_prompt moved to terminal/starship.nix
  };
}

