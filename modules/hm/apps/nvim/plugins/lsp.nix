{ ... }:
{
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;

      lspSignature.enable = false; # Incompatible with blink-cmp, use blink's builtin signature
      trouble = {
        enable = true;
      };

      # formatOnSave = true;
      inlayHints.enable = true;

      mappings = {
        format = "<leader>lf";
        goToDefinition = "gd";
        hover = "K";

        listImplementations = "<leader>li";

        nextDiagnostic = "g]";
        previousDiagnostic = "g[";
        openDiagnosticFloat = "<leader>d";

        renameSymbol = "<leader>rn";
      };

      servers.nixd.init_options = {
        nixpkgs = {
          expr = "import (builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).inputs.nixpkgs {}";
        };
        options = {
          nixos = {
            expr = "(builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).nixosConfigurations.nixos.options";
          };

          home-manager = {
            expr = "(builtins.getFlake (builtins.getEnv \"NH_FLAKE\")).homeConfigurations.\"adam@nixos\".options";
          };
        };
      };
    };

    luaConfigRC.lsp-diagnostics = ''
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      vim.diagnostic.config({
        signs = true,             -- Show the icons in the left column
        virtual_text = true,      -- Show text after the code line
        underline = true,         -- Underline the error in the code
        update_in_insert = false, -- Don't scream at me while I'm typing
        severity_sort = true,     -- Put errors above warnings
      })
    '';

    luaConfigRC.universalFormatOnSave = ''
      local lsp_format_group = vim.api.nvim_create_augroup("UniversalLspFormatOnSave", { clear = true })

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = lsp_format_group,
        pattern = "*",
        callback = function(args)
          local clients = vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/formatting" })
          if #clients == 0 then
            return
          end

          vim.lsp.buf.format({
            bufnr = args.buf,
            async = false,
            timeout_ms = 3000,
          })
        end,
      })
    '';
  };
}
