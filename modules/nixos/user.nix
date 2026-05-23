{
  lib,
  config,
  ...
}:
{
  config = {
    users.groups.adam = { };

    users.users.adam = {
      isNormalUser = true;
      group = "adam";
      extraGroups = [
        "wheel"
        "video"
        "adbusers"
        "networkmanager"
        "tty"
        "dialout"
        "plugdev"
        "uacess"
      ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa0c5F5UituMmDVqCYCwaOQXuEQFyHhbGTvY7HHU2MN root@nixos-laptop"
      ];
    };
  };
}