# i18n/fonts.nix — font packages and KMSCON console configuration
{ pkgs, lib, config }:
let
  cfg = config.modules.i18n.fonts;
in
{
  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];

    services.kmscon = {
      enable = false;
      hwRender = true;

      fonts = [
        {
          name = "JetBrainsMono Nerd Font";
          package = pkgs.nerd-fonts.jetbrains-mono;
        }
      ];
      extraConfig = "font-size=14";
    };
  };
}
