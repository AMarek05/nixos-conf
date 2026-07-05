{ lib, config, ... }:

{
  imports = [
    ./env.nix
    ./git.nix
    ./util.nix
  ];

  config = lib.mkIf config.hmModules.user.enable { };
}

