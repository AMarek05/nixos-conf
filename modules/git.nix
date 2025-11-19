{ ... }:
{
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
}
