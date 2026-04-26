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
  # Use beforeInit so fpath is updated BEFORE oh-my-zsh sources
  # (compinit runs inside oh-my-zsh.sh)
  programs.zsh.beforeInit = ''
    fpath=("${config.forge.package}/share/zsh/site-functions" $fpath)
  '';
}
