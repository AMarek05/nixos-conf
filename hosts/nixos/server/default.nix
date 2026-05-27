{ pkgs, lib, ... }:
{
  networking.firewall.enable = false;

  services.sillytavern = {
    enable = true;

    port = 8000;
  };

  services.caddy = {
    enable = true;

    virtualHosts."st.amarek.org".extraConfig = ''
      reverse_proxy localhost:8000
    '';
  };

  services.plex = {
    enable = true;
  };
}
