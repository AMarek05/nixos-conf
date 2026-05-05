# user/accounts.nix — user account creation and groups
{ pkgs, lib, config }:
let
  cfg = config.modules.user.accounts;
in
{
  config = lib.mkIf cfg.enable {
    users.users.adam = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "adbusers"
        "networkmanager"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
      ];
    };
  };
}
