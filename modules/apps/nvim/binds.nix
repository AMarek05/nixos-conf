{ ... }:
{
  programs.nvf.settings.vim = {
    binds.whichKey.enable = true;

    keymaps = [
      {
        key = "<Esc>";
        mode = [ "n" ];
        action = "<cmd>nohlsearch<CR>";
      }
      {
        key = "<leader>e";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.open_float()<cr>";
        desc = "Show diagnostic [E]rror messages";
      }
      {
        key = "<leader>q";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.setloclist()<cr>";
        desc = "Open diagnostic [Q]uickfix list";
      }

      # Clipboard
      {
        key = "<leader>y";
        mode = [ "n" ];
        action = "\"+y";
        desc = "[Y]ank into system cliboard";
      }
      {
        key = "<leader>p";
        mode = [ "n" ];
        action = "\"+p";
        desc = "[P]aste from system cliboard";
      }

      # Windows
      {
        key = "<C-h>";
        mode = [ "n" ];
        action = "<C-w><C-h>";
        desc = "Move focus to the left window";
      }
      {
        key = "<C-j>";
        mode = [ "n" ];
        action = "<C-w><C-j>";
        desc = "Move focus to the lower window";
      }
      {
        key = "<C-k>";
        mode = [ "n" ];
        action = "<C-w><C-k>";
        desc = "Move focus to the upper window";
      }
      {
        key = "<C-l>";
        mode = [ "n" ];
        action = "<C-w><C-l>";
        desc = "Move focus to the right window";
      }
      {
        key = "<C-w><";
        mode = [ "n" ];
        action = "<cmd>vertical resize -5<CR>";
        desc = "Decrease width";
      }
      {
        key = "<C-w>>";
        mode = [ "n" ];
        action = "<cmd>vertical resize +5<CR>";
        desc = "Increase width";
      }
      {
        key = "<C-w>-";
        mode = [ "n" ];
        action = "<cmd>resize +5<CR>";
        desc = "Increase width";
      }
      {
        key = "<C-w>+";
        mode = [ "n" ];
        action = "<cmd>resize +5<CR>";
        desc = "Increase width";
      }

      # Buffers
      {
        key = "<leader>bc";
        mode = [ "n" ];
        action = "<cmd>lua _G.CloseOtherBuffers()<CR>";
      }

      # Tabs
      {
        key = "<C-n>";
        mode = [ "n" ];
        action = "<cmd>tabn<CR>";
        desc = "Go to the next tab";
      }
      {
        key = "<C-p>";
        mode = [ "n" ];
        action = "<cmd>tabp<CR>";
        desc = "Go to the previous tab";
      }
      {
        key = "<leader>tn";
        mode = [ "n" ];
        action = "<cmd>tabnew<CR>";
        desc = "[T]ew [N]ew tab";
      }
      {
        key = "<leader>tc";
        mode = [ "n" ];
        action = "<cmd>tabc<CR>";
        desc = "[T]ab [C]lose";
      }
      {
        key = "<leader>tu";
        mode = [ "n" ];
        action = "<cmd>tabmove -<CR>";
        desc = "[T]ab move [U]p / left";
      }
      {
        key = "<leader>to";
        mode = [ "n" ];
        action = "<cmd>tabmove +<CR>";
        desc = "[T]ab m[O]ve right";
      }

      # Telescope
      {
        key = "<leader><leader>";
        mode = [ "n" ];
        action = "<cmd>Telescope buffers<CR>";
        desc = "[S]earch Buffers";
      }
      {
        key = "<leader>sf";
        mode = [ "n" ];
        action = "<cmd>Telescope find_files<CR>";
        desc = "[S]earch through [F]iles";
      }
      {
        key = "<leader>sg";
        mode = [ "n" ];
        action = "<cmd>Telescope live_grep<CR>";
        desc = "[S]earch [G]rep";
      }
      {
        key = "<leader>sb";
        mode = [ "n" ];
        action = "<cmd>Telescope buffers<CR>";
        desc = "[S]earch [B]uffers";
      }
      {
        key = "<leader>sh";
        mode = [ "n" ];
        action = "<cmd>Telescope help_tags<CR>";
        desc = "[S]earch [H]elp tags";
      }
      {
        key = "<leader>st";
        mode = [ "n" ];
        action = "<cmd>Telescope<CR>";
        desc = "[S]earch [T]elescope Builtins";
      }
      {
        key = "<leader>sr";
        mode = [ "n" ];
        action = "<cmd>Telescope resume<CR>";
        desc = "[S]earch [R]esume";
      }
      {
        key = "<leader>ss";
        mode = [ "n" ];
        action = "<cmd>Telescope treesitter<CR>";
        desc = "[S]earch Treesitter [S]ymbols";
      }
      {
        key = "<leader>sd";
        mode = [ "n" ];
        action = "<cmd>Telescope diagnostics<CR>";
        desc = "[S]earch [D]iagnostics";
      }
      {
        key = "<leader>s.";
        mode = [ "n" ];
        action = "<cmd>Telescope oldfiles<CR>";
        desc = "Telescope Oldfiles";
      }
      {
        key = "<leader>s/";
        mode = [ "n" ];
        action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
        desc = "Telescope Buffer Fuzzy Finder";
      }
      {
        key = "<leader>sa";
        mode = [ "n" ];
        action = "<cmd>Telescope aerial<CR>";
        desc = "Telescope AerialNvim";
      }

      # Plugins
      ## Oil
      {
        key = "-";
        mode = [ "n" ];
        action = "<cmd>Oil<CR>";
        desc = "Open Oil";
      }
      {
        key = "<leader>oo";
        mode = [ "n" ];
        action = "<cmd>Oil --float<CR>";
        desc = "[O]pen [O]il floating window";
      }

      ## Overseer
      {
        key = "<leader>or";
        mode = [ "n" ];
        action = "<cmd>OverseerRun<CR>";
        desc = "[O]verseer [R]un";
      }
      {
        key = "<leader>ot";
        mode = [ "n" ];
        action = "<cmd>OverseerToggle<CR>";
        desc = "[O]versee [T]oggle";
      }

      ## Undotree
      {
        key = "<leader>ou";
        mode = [ "n" ];
        action = "<cmd>UndotreeToggle<CR>";
        desc = "[O]pen [U]ndotree";
      }

      ## Git / Gitsigns / Diffview / Conflict
      {
        key = "<leader>gCo";
        mode = [ "n" ];
        action = "<cmd>GitConflictConflicthunk ours<CR>";
        desc = "[G]it Conflict choose [O]urs";
      }
      {
        key = "<leader>gCt";
        mode = [ "n" ];
        action = "<cmd>GitConflictConflicthunk theirs<CR>";
        desc = "[G]it Conflict choose [T]heirs";
      }
      {
        key = "<leader>gCb";
        mode = [ "n" ];
        action = "<cmd>GitConflictConflicthunk both<CR>";
        desc = "[G]it Conflict choose [B]oth";
      }
      {
        key = "<leader>gC0";
        mode = [ "n" ];
        action = "<cmd>GitConflictConflicthunk none<CR>";
        desc = "[G]it Conflict choose [N]one";
      }
      {
        key = "<leader>ghs";
        mode = [ "n" ];
        action = "<cmd>Git stage<CR>";
        desc = "[G]it Stage hunk";
      }
      {
        key = "<leader>ghu";
        mode = [ "n" ];
        action = "<cmd>Git reset<CR>";
        desc = "[G]it Undo stage hunk";
      }
      {
        key = "<leader>ghr";
        mode = [ "n" ];
        action = "<cmd>Gitsigns reset_hunk<CR>";
        desc = "[G]it Reset hunk";
      }
      {
        key = "<leader>ghS";
        mode = [ "n" ];
        action = "<cmd>Git stageBuffer<CR>";
        desc = "[G]it Stage buffer";
      }
      {
        key = "<leader>ghR";
        mode = [ "n" ];
        action = "<cmd>Gitsigns reset_buffer<CR>";
        desc = "[G]it Reset buffer";
      }
      {
        key = "<leader>ghP";
        mode = [ "n" ];
        action = "<cmd>Gitsigns preview_hunk<CR>";
        desc = "[G]it Preview hunk";
      }
      {
        key = "<leader>ghb";
        mode = [ "n" ];
        action = "<cmd>Git blame<CR>";
        desc = "[G]it Blame line";
      }
      {
        key = "<leader>ghd";
        mode = [ "n" ];
        action = "<cmd>Gitsigns diffthis<CR>";
        desc = "[G]it Diff this";
      }
      {
        key = "<leader>ghD";
        mode = [ "n" ];
        action = "<cmd>Gitsigns diffthis ~<CR>";
        desc = "[G]it Diff project";
      }
      {
        key = "<leader>gtb";
        mode = [ "n" ];
        action = "<cmd>Git blame<CR>";
        desc = "[G]it Toggle [B]lame";
      }
      {
        key = "<leader>gtd";
        mode = [ "n" ];
        action = "<cmd>Gitsigns toggle_deleted<CR>";
        desc = "[G]it Toggle [D]eleted";
      }
      {
        key = "<leader>gd";
        mode = [ "n" ];
        action = "<cmd>DiffviewOpen<CR>";
        desc = "[G]it Diffview open";
      }
      {
        key = "<leader>gD";
        mode = [ "n" ];
        action = "<cmd>DiffviewClose<CR>";
        desc = "[G]it Diffview close";
      }

      ## FLash
      {
        key = "s";
        mode = [
          "n"
          "x"
          "o"
        ];
        action = "<cmd>lua require('flash').jump()<CR>";
        silent = true;
        desc = "Flash Jump";
      }
      {
        key = "S";
        mode = [
          "n"
          "x"
          "o"
        ];
        action = "<cmd>lua require('flash').treesitter()<CR>";
        silent = true;
        desc = "Flash Treesitter";
      }
      {
        key = "r";
        mode = "o";
        action = "<cmd>lua require('flash').remote()<CR>";
        silent = true;
        desc = "Remote Flash";
      }
    ];

    luaConfigRC.whichkey = ''
      local wk = require("which-key")
      wk.add({
        { "<leader>s", group = "Search" },
        { "<leader>o", group = "Open" },
        { "<leader>u", group = "Undo" },
        { "<leader>b", group = "Buffer" },
        { "<leader>t", group = "Tabs" },
        { "<leader>g", group = "Git" },
        { "<leader>gh", group = "Git Hunk" },
        { "<leader>gt", group = "Git Toggle" },
        { "<leader>gC", group = "Git Conflict" },
        { "<leader>l", group = "LSP" },
        { "<leader>lg", group = "Goto" },
        { "<leader>lt", group = "LSP Toggle" },
        { "<leader>lw", group = "Workspace" },
        { "<leader>x", group = "Trouble" },
      })
    '';

    luaConfigRC.closeOtherBuffers = ''
      _G.CloseOtherBuffers = function()
        local current_buf = vim.api.nvim_get_current_buf()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
          local is_listed = vim.bo[bufnr].buflisted

          if bufnr ~= current_buf and is_loaded and is_listed then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
          end
        end
      end
    '';
  };
}

