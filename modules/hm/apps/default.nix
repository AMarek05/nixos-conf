{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./dolphin.nix
    ./nvf.nix
    ./stylix.nix
    ./forge.nix
    ./packages.nix
  ];

  options.hmModules.apps = {
    enable = lib.mkEnableOption "apps";
  };

  config = lib.mkIf config.hmModules.apps.enable {
    home.packages = with pkgs; [ nh ];
  };
}
