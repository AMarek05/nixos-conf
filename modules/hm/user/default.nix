{ lib, ... }:

{
  imports = [
    ./env.nix
    ./git.nix
    ./util.nix
  ];

  options.hmModules.user = {
    enable = lib.mkEnableOption "user environment (env, git, util)";
  };

  config = lib.mkIf config.hmModules.user.enable { };
}