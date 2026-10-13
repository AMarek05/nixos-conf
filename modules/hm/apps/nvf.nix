{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./nvim
  ];

  config = lib.mkIf (lib.my.isEnabled config "hmModules" "apps.nvf") {

    programs.nvf = {
      enable = true;

      settings.vim = {
        options.shell = "${pkgs.zsh}/bin/zsh";
        theme = {
          enable = lib.mkForce true;
          name = lib.mkForce "catppuccin";
          style = "mocha";
        };

        globals.maplocalleader = " ";

        luaConfigPost = ''
          vim.api.nvim_set_hl(0, "@property", { fg = "#cba6f7" })
        '';
      };

    };
  };
}
