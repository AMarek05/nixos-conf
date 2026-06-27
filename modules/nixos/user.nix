{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.user = {
    enable = lib.mkEnableOption "user configuration";
  };

  config = lib.mkIf config.nixosModules.user.enable {
    users.groups.adam = { };

    users.users.adam = {
      isNormalUser = true;
      group = "adam";
      shell = pkgs.zsh;

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
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSrgBs2fy3oRYtbmbXNEkJ8JpqS2L8U/RPqVEojiOAu6OWzT8EXaMHwHhxMjXIXp2fzCaXrbZCV9is9rckuLuQ= nixos-laptop"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMVue17Ck5epd5LBWWWd9Es+XN+IFtdkMxy2NHkFbtghXH+1lujMQxTjv3ZUD0R2pt8jfycdNqNmiH4QnjYpSgI= id-nixos"
      ];
    };

    programs.zsh.enable = true;

    environment.sessionVariables = {
      NH_FLAKE = "/home/adam/sys";
    };
  };
}
