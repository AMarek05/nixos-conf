{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.sandbox = {
    enable = lib.mkEnableOption "Sandboxing";
  };

  config = lib.mkIf config.nixosModules.sandbox.enable {
    services.flatpak.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.systemPackages = with pkgs; [
      distrobox
    ];

    virtualisation.containers.storage.settings = {
      storage = {
        driver = "overlay";
        graphroot = "/home/adam/media/podman-storage";
        runroot = "/run/containers/storage";
      };
    };
  };
}
