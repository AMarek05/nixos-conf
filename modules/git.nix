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

      signing = {
        key = "/home/adam/.ssh/git";
        signByDefault = true;
        format = "ssh";
      };

      settings = {
        alias = {
          lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        };

        user = {
          name = "Adam Marek";
          email = "118975111+AMarek05@users.noreply.github.com";
          useConfigOnly = true;
        };
      };

      settings = {
        gpg.ssh.allowedSignersFile = "/home/adam/.ssh/allowed_signers";
        init.defaultBranch = "main";
      };
    };
  };
}
