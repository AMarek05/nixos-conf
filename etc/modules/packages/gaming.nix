# packages/gaming.nix — gaming and VPN packages
{ pkgs }:
{
  environment.systemPackages = with pkgs; [
    steam-run-free

    proton-vpn-cli
    proton-vpn

    (symlinkJoin {
      name = "proton-authenticator-wrapped";
      paths = [ pkgs.proton-authenticator ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/proton-authenticator \
          --set GDK_BACKEND x11 \
          --set WEBKIT_DISABLE_COMPOSITOR_ANIMATIONS 1 \
          --set WEB_KIT_DISABLE_DMABUF 1
      '';
    })

    mullvad-vpn
    (symlinkJoin {
      name = "mullvad-completions";
      paths = [ pkgs.mullvad ];
      postBuild = ''
        # Delete the bin directory so the incompatible CLI isn't added to your PATH
        rm -rf $out/bin
      '';
    })
  ];
}
