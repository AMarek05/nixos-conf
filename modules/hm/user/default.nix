{ lib, config, ... }:

{
  # Sub-modules (util, git, env) are auto-imported by the catalog.
  config = lib.mkIf config.hmModules.user.enable { };
}

