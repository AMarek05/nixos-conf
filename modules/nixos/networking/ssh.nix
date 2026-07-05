{ lib, config, ... }:
{
  config = lib.mkIf (config.nixosModules.networking.enable && config.nixosModules.networking.ssh.enable) {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
