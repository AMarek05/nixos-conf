# services/sshd.nix — OpenSSH daemon
{ lib, config }:
let
  cfg = config.modules.services.sshd;
in
{
  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
