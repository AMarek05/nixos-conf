{
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.forge.homeManagerModules.default
  ];

  forge = {
    enable = true;
    syncBase = "${config.home.homeDirectory}/sync";
    githubUser = "AMarek05";
    languages = [
      "rust"
      "python"
      "c"
      "cpp"
      "java"
      "nix"
      "r"
    ];
    includes = [
      "git"
      "overseer"
    ];
  };

  # Completions are installed by the module via home.file
  # ("share/zsh/site-functions/_forge")
  # Use prependZshrc so fpath is updated BEFORE compinit runs
  programs.zsh.initExtraBeforeCompInit = ''
    fpath=("${config.forge.package}/share/zsh/site-functions" $fpath)
  '';
}
