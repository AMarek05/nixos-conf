{
  git = {
    enable = true;
    neogit.enable = true;
    gitsigns.setupOpts = {
      signs = {
        add = {
          text = "+";
        };
        change = {
          text = "~";
        };
        delete = {
          text = "_";
        };
        topdelete = {
          text = "‾";
        };
        changedelete = {
          text = "~";
        };
      };
    };
  };
}
