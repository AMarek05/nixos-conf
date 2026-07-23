{ config, pkgs, ... }:
let
  name = config.networking.hostName;
in
{
  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "5s";
    };
  };

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users = {
    users."${name}" = {
      group = name;
      isSystemUser = true;

      shell = pkgs.bash;
      home = "/var/lib/${name}";

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSrgBs2fy3oRYtbmbXNEkJ8JpqS2L8U/RPqVEojiOAu6OWzT8EXaMHwHhxMjXIXp2fzCaXrbZCV9is9rckuLuQ="
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMVue17Ck5epd5LBWWWd9Es+XN+IFtdkMxy2NHkFbtghXH+1lujMQxTjv3ZUD0R2pt8jfycdNqNmiH4QnjYpSgI= id-nixos"
      ];
    };
  };
}
