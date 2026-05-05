# security/default.nix
{ lib }:
{
  imports = [
    ./pam.nix
    ./gnupg.nix
  ];

  options.modules.security = {
    enable = lib.mkEnableOption "security";
    pam = {
      enable = lib.mkEnableOption "security/pam";
    };
    gnupg = {
      enable = lib.mkEnableOption "security/gnupg";
    };
  };
}
