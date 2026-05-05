# etc/configuration.nix — thin wire for NixOS system configuration
# All system config is split into etc/modules/. Import modules/default.nix here.
# Devices can disable domains they don't need via module options.
{
  lib,
  ...
}:

{
  imports = [
    ./modules/default.nix
  ];

  # system.stateVersion is required by NixOS — do not remove
  system.stateVersion = "25.05";
}
