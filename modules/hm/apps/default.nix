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
    # ./dolphin.nix ./nvf.nix ./stylix.nix ./forge.nix ./packages.nix
    # These are auto-imported by the catalog via the `sub` entries.
  ];

  config = lib.mkIf config.hmModules.apps.enable {
    home.packages = with pkgs; [ nh ];
  };
}
