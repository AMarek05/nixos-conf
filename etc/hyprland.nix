{ inputs, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    catppuccin-sddm
  ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-sugar-dark-theme";
  };

  programs.hyprland = {
    enable = true;

    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    withUWSM = true;
    xwayland.enable = true;
  };
}
