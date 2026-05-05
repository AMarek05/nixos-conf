# user/default.nix
{ lib }:
{
  imports = [
    ./accounts.nix
    ./system-shells.nix
  ];

  options.modules.user = {
    enable = lib.mkEnableOption "user";
    accounts = {
      enable = lib.mkEnableOption "user/accounts";
    };
    system-shells = {
      enable = lib.mkEnableOption "user/system-shells";
    };
  };
}
