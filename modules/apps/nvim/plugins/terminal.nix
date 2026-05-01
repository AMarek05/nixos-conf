{
  programs.nvf.settings.vim = {
    terminal.toggleterm = {
      enable = true;

      mappings.open = "<c-t>";

      setupOpts = {
        direction = "horizontal";
        size = 15;
        enable_winbar = true;
      };

      lazygit = {
        enable = true;
        direction = "float";
        mappings.open = "<leader>gg";
      };
    };
  };
}