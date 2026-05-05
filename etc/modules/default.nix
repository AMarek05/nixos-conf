# etc/modules/default.nix — system config module enable flags
# All domains are enabled by default. Devices can disable what they don't need.
{ lib }:

{
  options.modules = {
    boot = {
      enable = lib.mkEnableOption "boot" // {
        description = "Boot loader and kernel configuration";
      };
      loader = {
        enable = lib.mkEnableOption "boot/loader";
      };
      kernel = {
        enable = lib.mkEnableOption "boot/kernel";
      };
    };

    networking = {
      enable = lib.mkEnableOption "networking" // {
        description = "Networking configuration";
      };
      networkmanager = {
        enable = lib.mkEnableOption "networking/networkmanager";
      };
      firewall = {
        enable = lib.mkEnableOption "networking/firewall";
      };
      services = {
        enable = lib.mkEnableOption "networking/services";
      };
    };

    user = {
      enable = lib.mkEnableOption "user" // {
        description = "User accounts and system-wide shells";
      };
      accounts = {
        enable = lib.mkEnableOption "user/accounts";
      };
      system-shells = {
        enable = lib.mkEnableOption "user/system-shells";
      };
    };

    services = {
      enable = lib.mkEnableOption "services" // {
        description = "System services";
      };
      audio = {
        enable = lib.mkEnableOption "services/audio";
      };
      syncthing = {
        enable = lib.mkEnableOption "services/syncthing";
      };
      flatpak = {
        enable = lib.mkEnableOption "services/flatpak";
      };
      sshd = {
        enable = lib.mkEnableOption "services/sshd";
      };
      gnome-keyring = {
        enable = lib.mkEnableOption "services/gnome-keyring";
      };
    };

    i18n = {
      enable = lib.mkEnableOption "i18n" // {
        description = "Internationalisation and locale";
      };
      locale = {
        enable = lib.mkEnableOption "i18n/locale";
      };
      console = {
        enable = lib.mkEnableOption "i18n/console";
      };
    };

    packages = {
      enable = lib.mkEnableOption "packages" // {
        description = "System packages";
      };
      system = {
        enable = lib.mkEnableOption "packages/system";
      };
      gaming = {
        enable = lib.mkEnableOption "packages/gaming";
      };
    };

    nix = {
      enable = lib.mkEnableOption "nix" // {
        description = "Nix configuration";
      };
      settings = {
        enable = lib.mkEnableOption "nix/settings";
      };
      ld = {
        enable = lib.mkEnableOption "nix/ld";
      };
    };

    security = {
      enable = lib.mkEnableOption "security" // {
        description = "Security configuration";
      };
      pam = {
        enable = lib.mkEnableOption "security/pam";
      };
      gnupg = {
        enable = lib.mkEnableOption "security/gnupg";
      };
    };
  };

  imports = [
    ./boot/default.nix
    ./networking/default.nix
    ./user/default.nix
    ./services/default.nix
    ./i18n/default.nix
    ./packages/default.nix
    ./nix/default.nix
    ./security/default.nix
  ];
}
