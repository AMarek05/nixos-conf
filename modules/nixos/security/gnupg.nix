{ lib, config, ... }:
{
  config = lib.mkIf (lib.my.isEnabled config "nixosModules" "security.gnupg") {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };
  };
}
