{ config, lib, ... }:
let
  cfg = config.modules.git;
in
{
  options.modules.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings.user = {
        name = "Adam Marek";
        email = "118975111+AMarek05@users.noreply.github.com";
        useConfigOnly = true;
      };

      signing = {
        key = "/home/adam/.ssh/git";
        signByDefault = true;
        signer = "ssh";
      };

      settings = {
        gpg.ssh.allowedSignersFile = "/home/adam/.ssh/allowed_signers";
        gpg.format = "ssh";
        init.defaultBranch = "main";
      };
    };
  };
}
