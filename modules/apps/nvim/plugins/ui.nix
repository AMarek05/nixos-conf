{ lib, ... }:
{
  programs.nvf.settings.vim = {

    visuals.nvim-web-devicons.enable = true;

    treesitter.context = {
      enable = true;
      setupOpts = {
        maxLines = 5;
        multiline_threshold = 1;
        trim_scope = "outer";
        mode = "cursor";
      };
    };

    ui = {

      borders.enable = true;
      illuminate.enable = true;

      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };

      noice.enable = true;
      noice.setupOpts = {
        cmdline.format = {
          filter = {
            pattern = "^:%s*!"; # Detects :!
            icon = ""; # Change this to any icon you want
            lang = "bash"; # Force Bash syntax highlighting

            # Optional: changing the title of the input box
            title = " Shell ";
          };
          routes = [
            {
              view = "popup";
              filter = {
                event = "msg_show";
                kind = "shell_out";
                find = ".*"; # Catch all output text
              };
              opts = {
                persistent = true; # if you want it to stay until you close it manually
              };
            }
            {
              filter = {
                event = "notify";
                find = "require%('lspconfig'%)";
              };
              opts = {
                skip = true;
              };
            }
          ];
        };
      };
    };

    statusline.lualine = {
      enable = true;
      setupOpts = {
        options = {
          theme = "auto";
          # Subtle vertical line for separating components within the same section
          component_separators = {
            left = "❘";
            right = "❘";
          };
          # Smooth pill shapes where section backgrounds change colors
          section_separators = {
            left = "";
            right = "";
          };
          globalstatus = true;
        };
      };

      activeSection = {
        a = [
          ''{ "mode", icons_enabled = true }''
        ];

        b = [
          ''{ "filetype", colored = true, icon_only = true, icon = { align = 'left' }, separator = "", padding = { left = 2, right = 1 } }''
          ''{ "filename", symbols = {modified = ' ', readonly = ' '}, padding = { left = 1, right = 1 } }''
        ];

        c = [
          ''{ "diff", colored = true, symbols = {added = '+', modified = '~', removed = '-'} }''
        ];

        x = [
          ''
            {
              function()
                local buf_ft = vim.bo.filetype
                local excluded_buf_ft = { toggleterm = true, NvimTree = true, ["neo-tree"] = true, TelescopePrompt = true }
                if excluded_buf_ft[buf_ft] then return "" end
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                if vim.tbl_isempty(clients) then return "No Active LSP" end
                local active_clients = {}
                for _, client in ipairs(clients) do table.insert(active_clients, client.name) end
                return table.concat(active_clients, ", ")
              end,
              icon = ' ',
              padding = { left = 1, right = 1 },
            }
          ''
          ''
            { 
              "diagnostics", 
              sources = {'nvim_diagnostic'}, 
              symbols = {error = '󰅙 ', warn = ' ', info = ' ', hint = '󰌵 '}, 
              colored = true,
              padding = { left = 1, right = 1 },
            }
          ''
        ];

        y = [
          ''{ "searchcount", maxcount = 999, timeout = 120, padding = { left = 1, right = 1 } }''
          ''{ "branch", icon = '', padding = { left = 1, right = 1 } }''
        ];

        z = [
          ''{ "progress", padding = { left = 1, right = 1 } }''
          ''{ "location", padding = { left = 1, right = 1 } }''
          ''{ "fileformat", symbols = { unix = '', dos = '', mac = '' }, padding = { left = 1, right = 1 } }''
        ];
      };
    };

    dashboard.alpha = {
      enable = true;
      theme = null;
      layout = [
        {
          type = "padding";
          val = lib.generators.mkLuaInline "function() return math.floor(vim.o.lines * 0.25) end";
        }
        {
          type = "text";
          val = [
            "      _   __               _         "
            "     / | / /__  ____ _   _(_)____ ___"
            "    /  |/ / _ \\/ __ \\ | / / / __ `__ \\"
            "   / /|  /  __/ /_/ / |/ / / / / / / /"
            "  /_/ |_/\\___/\\____/|___/_/_/ /_/ /_/ "
          ];
          opts = {
            position = "center";
            hl = "String";
          };
        }
        {
          type = "padding";
          val = 2;
        }
        {
          type = "group";
          val = lib.generators.mkLuaInline ''
            {
              require("alpha.themes.dashboard").button("n", "  New file", "<cmd> ene <CR>"),
              require("alpha.themes.dashboard").button("f", "  Find file", "<cmd> Telescope find_files <CR>"),
              require("alpha.themes.dashboard").button("r", "  Recent files", "<cmd> Telescope oldfiles <CR>"),
              require("alpha.themes.dashboard").button("g", "  Find word", "<cmd> Telescope live_grep <CR>"),
              require("alpha.themes.dashboard").button("o", "  File browser", "<cmd> Oil <CR>"),
              require("alpha.themes.dashboard").button("q", "  Quit", "<cmd> qa <CR>")
            }
          '';
          opts = {
            position = "center";
            spacing = 1;
          };
        }
      ];
    };
  };
}
