{ lib, config, pkgs, ... }:
{
  # Cross-cutting security config: polkit + udev packages.
  # Sub-modules (gnupg, tpm2, keyring) are auto-imported.
  config = lib.mkIf config.nixosModules.security.enable {
    security.polkit.enable = true;

    services.udev.packages = with pkgs; [
      avrdude
      avrdudess
    ];
  };
}
