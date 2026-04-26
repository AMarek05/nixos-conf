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
        key = "<leader>s.";
        mode = [ "n" ];
        action = "<cmd>Telescope oldfiles<CR>";
        desc = "Telescope Oldfiles";
      }
      {
        key = "<leader>s/";
        mode = [ "n" ];
        action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
        desc = "Telescope Oldfiles";
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
        desc = "Run task";
      }
      {
        key = "<leader>ot";
        mode = [ "n" ];
        action = "<cmd>OverseerToggle<CR>";
        desc = "Toggle task list";
      }

      ## Undotree
      {
        key = "<leader>u";
        mode = [ "n" ];
        action = "<cmd>UndotreeToggle<CR>";
        desc = "Open [U]ndotree";
      }

      ## Git / Gitsigns
      {
        key = "<leader>gtb";
        mode = [ "n" ];
        action = "<cmd>Git blame<CR>";
        desc = "[Git] [T]oggle [B]lame";
      }
      {
        key = "<leader>gtd";
        mode = [ "n" ];
        action = "<cmd>Gitsigns toggle_deleted<CR>";
        desc = "[Git] [T]oggle [D]eleted";
      }

      ## Diffview [g]it
      {
        key = "<leader>gd";
        mode = [ "n" ];
        action = "<cmd>DiffviewOpen<CR>";
        desc = "[Git] Diffview open";
      }
      {
        key = "<leader>gD";
        mode = [ "n" ];
        action = "<cmd>DiffviewClose<CR>";
        desc = "[Git] Diffview close";
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
        { "<leader>gt", group = "Git" },
        { "<leader>gtb", group = "Git", desc = "Toggle blame" },
        { "<leader>gtd", group = "Git", desc = "Toggle deleted" },
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