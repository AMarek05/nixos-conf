{ inputs, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --user-menu \
          --theme \"border=magenta;text=cyan;prompt=green;time=yellow;action=blue;button=magenta;container=black;input=yellow\" \
          --cmd 'start-hyprland'";
        user = "greeter";
      };
    };
  };

  programs.hyprland = {
    enable = true;

    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    xwayland.enable = true;
  };
}
