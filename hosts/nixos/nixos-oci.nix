# nixos-oci — OCI Ampere A1 (aarch64) VPS, hosts the Pangolin reverse-proxy. nixos-anywhere install.
{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/oci-image.nix"
  ];

  # Match nixos-server: SOPS reads from a dedicated file, not the host SSH key.
  networking.hostName = lib.mkForce "nixos-oci";

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    neovim
    curl
  ];

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa0c5F5UituMmDVqCYCwaOQXuEQFyHhbGTvY7HHU2MN root@nixos-laptop"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHSrgBs2fy3oRYtbmbXNEkJ8JpqS2L8U/RPqVEojiOAu6OWzT8EXaMHwHhxMjXIXp2fzCaXrbZCV9is9rckuLuQ= nixos-laptop"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMVue17Ck5epd5LBWWWd9Es+XN+IFtdkMxy2NHkFbtghXH+1lujMQxTjv3ZUD0R2pt8jfycdNqNmiH4QnjYpSgI= id-nixos"
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  nixosModules.desktop.enable = false;
  nixosModules.gaming.enable = false;
  nixosModules.security.enable = false;
  nixosModules.vpn.enable = false;

  nixosModules.networking.syncthing.enable = false;
  nixosModules.shell.zsh.enable = false;
  nixosModules.shell.direnv.enable = false;
  nixosModules.shell.dconf.enable = false;
  nixosModules.system.packages.enable = false;

  system.stateVersion = lib.mkForce "26.05";
}
