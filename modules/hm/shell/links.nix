{ config, lib, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "hmModules" "shell.links") {
    # starship.toml and .transient_prompt moved to terminal/starship.nix
  };
}
