{ ... }:
{
  programs.nvf.settings.vim = {
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = false;

      clang.enable = true;
      python.enable = true;
      zig.enable = false;
      go.enable = true;
      bash.enable = true;

      java.enable = true;

      rust = {
        enable = true;
        lsp.enable = true;
        lsp.package = [ "rust-analyzer" ];
      };

      nix = {
        enable = true;
        format.type = [ "nixfmt" ];
        lsp.servers = [ "nixd" ];
      };
    };
  };
}
