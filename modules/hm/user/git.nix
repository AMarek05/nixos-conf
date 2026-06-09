{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hmModules.user.git;

in
{
  options.hmModules.user.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ git-lfs ];
    programs.git = {
      enable = true;

      signing = {
        key = "/home/adam/.ssh/id_tpm.pub";
        signByDefault = true;
        format = "ssh";
      };

      ignores = [
        ".direnv/"
        ".forge/"
        ".cache/"

        ".wl"
        ".envrc"
        ".clangd"
        "compile_commands.json"
      ];

      settings = {
        alias = {
          lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        };

        user = {
          name = "Adam Marek";
          email = "amarek.git@gmail.com";
          useConfigOnly = true;
        };

        gpg.ssh.allowedSignersFile = "/home/adam/.ssh/allowed_signers";
        init.defaultBranch = "main";

        push.autoSetupRemote = true;
      };
    };
  };
}
