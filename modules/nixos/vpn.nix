{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.vpn = {
    enable = lib.mkEnableOption "VPN clients (Mullvad, ProtonVPN)";
  };

  config = lib.mkIf config.nixosModules.vpn.enable {
    environment.systemPackages = with pkgs; [
      proton-vpn-cli
      proton-vpn
      (symlinkJoin {
        name = "proton-authenticator-wrapped";
        paths = [ proton-authenticator ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/proton-authenticator \
            --set GDK_BACKEND x11 \
            --set WEBKIT_DISABLE_COMPOSITOR_ANIMATIONS 1 \
            --set WEB_KIT_DISABLE_DMABUF 1
        '';
      })
    ];
  };
}
