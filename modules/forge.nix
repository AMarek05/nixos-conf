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
  programs.zsh.initContent = ''
    # Forge completions — must be in fpath before compinit
    fpath=("${config.forge.package}/share/zsh/site-functions" $fpath)
  '';
}
