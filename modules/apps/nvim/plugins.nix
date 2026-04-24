{ inputs }:
{
  programs.nvf.settings.vim = {
    imports = [
      ./plugins/util.nix
      ./plugins/autocomplete.nix
      ./plugins/tools.nix
      ./plugins/lsp.nix
      ./plugins/languages.nix
      ./plugins/ui.nix
      ./plugins/git.nix
    ];
  };
}
