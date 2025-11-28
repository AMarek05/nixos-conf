{
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

  options.modules.apps.nvf = {
    enable = lib.mkEnableOption "nvf";
  };

  config = lib.mkIf config.modules.apps.nvf.enable {

    programs.nvf = {
      enable = true;

      settings.vim = {
        theme = {
          name = lib.mkForce "tokyonight";
          style = "night";
        };

        globals.maplocalleader = " ";
      };

    };
  };
}
