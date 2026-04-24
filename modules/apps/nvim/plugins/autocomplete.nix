{
  autocomplete.blink-cmp = {
    enable = true;
    friendly-snippets.enable = true;
    mappings.next = null;
    setupOpts = {
      sources.default = [
        "lsp"
        "path"
        "snippets"
      ];
      cmdline = {
        completion = {
          list = {
            selection = {
              preselect = true;
              auto_insert = true;
            };
          };
          menu = {
            auto_show = false;
          };
          ghost_text = {
            enabled = false;
          };
        };
        keymap = {
          preset = "default";
          "<CR>" = [
            "fallback"
          ];
        };
      };
      keymap = {
        preset = "none";
        "<Tab>" = [
          "select_next"
          "fallback"
        ];
        "<C-n>" = [
          "snippet_forward"
          "fallback"
        ];
        "<C-p>" = [
          "snippet_backward"
          "fallback"
        ];
        "<A-k>" = [
          "scroll_documentation_up"
          "fallback"
        ];
        "<A-j>" = [
          "scroll_documentation_down"
          "fallback"
        ];
      };
    };
  };
}
