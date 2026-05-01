{
  inputs,
  ...
}:
{
  imports = [
    inputs.forge.homeManagerModules.default
  ];

  forge = {
    enable = true;

    githubUser = "AMarek05";
    editor = "nvim";
  };
}
