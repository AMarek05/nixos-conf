{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.modules.console = {
    enable = lib.mkEnableOption "console (fonts, keymap, kmscon)";
  };

  config = lib.mkIf config.modules.console.enable {
    console = {
      enable = true;
      packages = with pkgs; [ terminus_font ];
      font = "ter-v16n";
      keyMap = "us";
    };

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
