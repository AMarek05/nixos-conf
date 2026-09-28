{ pkgs, lib, ... }:
let
  smartLatexConverter = pkgs.writeShellScriptBin "smart-latex-converter" ''
    input="$(cat)"
    # If the input has no internal newlines and is short, prefer latex2text for flat 1D output
    if ! echo "$input" | grep -q $'\n' && command -v latex2text >/dev/null 2>&1; then
      echo "$input" | latex2text | tr -d '\n'
    else
      # Otherwise pass to utftex and strip only the trailing newline
      echo "$input" | utftex | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
    fi
  '';
in
{
  programs.nvf.settings.vim = {
    extraPackages = with pkgs; [
      custom.utftex
      python3Packages.pylatexenc
      smartLatexConverter

      rustc
      cargo
    ];

    treesitter = {
      grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
        latex
        html
        yaml
      ];
    };

    lsp.servers = {
      nixd.settings.nixd.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = false;

      python.enable = true;
      go.enable = true;
      bash.enable = true;

      java.enable = true;

      markdown = {
        enable = true;
        extensions = {
          render-markdown-nvim = {
            enable = true;
            setupOpts = {
              latex = {
                enabled = true;
                converter = "smart-latex-converter";
              };
            };
          };
        };
      };

      clang = {
        enable = true;
        lsp.enable = true;
      };

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
