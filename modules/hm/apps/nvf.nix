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
    ./nvim/binds.nix
    ./nvim/opts.nix
    ./nvim/plugins.nix
  ];

  options.hmModules.apps.nvf = {
    enable = lib.mkEnableOption "nvf";
  };

  config = lib.mkIf config.hmModules.apps.nvf.enable {

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
