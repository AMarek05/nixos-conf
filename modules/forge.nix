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
}
