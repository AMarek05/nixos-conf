{ ... }:
{
  programs.nvf.settings.vim.options = {
    expandtab = true;
    tabstop = 2;
    shiftwidth = 2;
    softtabstop = 2;

    number = true;
    relativenumber = true;

    mouse = "a";
    showmode = false;

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
  programs.nvf.settings.vim.luaConfigRC.clipboard-setup = ''
    -- Create an autocommand group to prevent duplication
    local clip_group = vim.api.nvim_create_augroup("YankToSystem", { clear = true })

    vim.api.nvim_create_autocmd("TextYankPost", {
      group = clip_group,
      pattern = "*",
      callback = function()
        -- Only sync if the operator was 'y' (yank)
        if vim.v.event.operator == "y" then
          -- Copy the contents of the unnamed register (") to the system register (+)
          vim.fn.setreg("+", vim.fn.getreg('"'))
        end
      end,
    })
  '';
}
