{ lib, config, ... }:
{
  config = lib.mkIf (config.nixosModules.security.enable && config.nixosModules.security.gnupg.enable) {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };
  };
}
