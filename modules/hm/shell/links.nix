{ config, lib, ... }:
{
  config = lib.mkIf (config.hmModules.shell.enable && config.hmModules.shell.links.enable) {
    # starship.toml and .transient_prompt moved to terminal/starship.nix
  };
}
