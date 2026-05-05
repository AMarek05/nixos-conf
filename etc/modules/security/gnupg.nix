# security/gnupg.nix — GnuPG agent configuration
{ lib, config }:
let
  cfg = config.modules.security.gnupg;
in
{
  config = lib.mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };

    programs.mtr.enable = true;
  };
}
