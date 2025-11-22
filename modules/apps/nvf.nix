{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  programs.nvf = {
    enable = true;

    settings.vim = {
      options = {
        expandtab = true;
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;

        number = true;
        relativenumber = true;

        mouse = "a";
        showmode = false;

        clipboard = "unnamedplus";
        breakindent = true;
        undofile = true;

        ignorecase = true;
        smartcase = true;

        signcolumn = "yes";

        updatetime = 250;
        timeoutlen = 300;

        splitright = true;
        splitbelow = true;

        list = true;
        listchars = "tab:» ,trail:·,nbsp:␣";

        inccommand = "split";
        cursorline = true;
        scrolloff = 5;

        hlsearch = true;
      };
      keymaps = [
        {
          key = "<Esc>";
          mode = [ "n" ];
          action = "<cmd>nohlsearch<CR>";
        }
        {
          key = "<leader>e";
          mode = [ "n" ];
          action = "vim.diagnosctic.open_float";
          desc = "Show diagnostic [Error] messages";
        }
        {
          key = "<leader>q";
          mode = [ "n" ];
          action = "vim.diagnostic.setloclist";
          desc = "Open diagnostic [Q]uickfix list";
        }
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
          key = "<leader>nt";
          mode = [ "n" ];
          action = "<cmd>tabnew<CR>";
          desc = "[N]ew [T]ab";
        }
      ];
    };
  };
}
