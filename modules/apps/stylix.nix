{ pkgs, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    # Change to match about:profiles
    targets.zen-browser.profileNames = [ "adam" ];

    targets.gtk.enable = true;
    targets.gnome.enable = false;

    targets.starship.enable = false;

    image = ../../store/wallpaper.webp;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
    };
  };
}
