{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixosModules.security = {
    enable = lib.mkEnableOption "security (gnupg, pam, dconf, gnome-keyring)";
  };

  config = lib.mkIf config.nixosModules.security.enable {

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };

    security.pam.services.hyprlock = { };

    security.polkit.enable = true;

    services.udev.packages = with pkgs; [
      avrdude
      avrdudess
    ];

    security.tpm2 = {
      enable = true;
      abrmd.enable = true;
      pkcs11.enable = true;
      applyUdevRules = true;
    };

    programs.ssh.startAgent = true;

    systemd.user.services.ssh-agent = {
      environment = {
        TPM2_PKCS11_STORE = "/var/lib/tpm2-pkcs11";
        TPM2_PKCS11_BACKEND = "esysdb";
        TPM2TOOLS_TCTI = "tabrmd:bus_type=system";
      };

      serviceConfig = {
        Type = lib.mkForce "forking";
        ExecStart = lib.mkForce "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent -P /nix/store/*,/run/current-system/sw/lib/*";
      };
    };

    users.users.adam.extraGroups = [ "tss" ];

    environment.systemPackages = with pkgs; [
      sops
      ssh-to-age
      tpm2-tools
      pkcs11-provider
    ];

    environment.sessionVariables = {
      TPM2_PKCS11_STORE = "/var/lib/tpm2-pkcs11";
      TPM2_PKCS11_BACKEND = "esysdb";
    };

    systemd.tmpfiles.rules = [
      # Type  Path                  Mode  User  Group  Age  Argument
      "d      /var/lib/tpm2-pkcs11  0700  adam  tss    -    -"
    ];

    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
