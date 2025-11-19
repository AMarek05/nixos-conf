{ config, lib, ... }:
let 
  cfg = config.modules.git;
in
{
  options.modules.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable git";
    };
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
        gpg.format = "ssh";
        init.defaultBranch = "main";
      };
    };
  };
}
