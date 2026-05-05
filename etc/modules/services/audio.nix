# services/audio.nix — pipewire, rtkit, gamemode
{ lib, config }:
let
  cfg = config.modules.services.audio;
in
{
  config = lib.mkIf cfg.enable {
    programs.gamemode.enable = true;

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;

      wireplumber.extraConfig."99-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_input.*"; }
              { "node.name" = "~alsa_output.*"; }
            ];
            actions = {
              update-props = {
                "session.suspend-timeout-seconds" = 0;
              };
            };
          }
        ];
      };
      wireplumber.extraConfig."99-alsa-headroom" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.*"; }
            ];
            actions = {
              update-props = {
                "api.alsa.headroom" = 2048;
              };
            };
          }
        ];
      };
    };
  };
}
