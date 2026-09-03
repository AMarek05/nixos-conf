{ ... }:
{
  programs.nvf.settings.vim = {
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = false;

      clang.enable = true;
      python.enable = true;
      go.enable = true;
      bash.enable = true;

      java.enable = true;

      rust = {
        enable = true;
        lsp.enable = true;
      };

      zig = {
        enable = true;
        lsp.enable = true;
      };

      odin = {
        enable = true;
        lsp.enable = true;
      };

      nix = {
        enable = true;
        format.type = [ "nixfmt" ];
        lsp.servers = [ "nixd" ];
      };
    };
  };
}
